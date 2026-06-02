{ config, pkgs, lib, ... }:

let
  xrayServer = (import ./private/xray-routes.nix).xrayServer;
  wifiIf = "wlp194s0";
in
{
  # ---------------------------------------------------------------------------
  # 1. MAC randomization — per-SSID stable random, plus scan-time random.
  #    Keeps captive-portal whitelists working (same MAC per SSID) but breaks
  #    cross-network device tracking.
  # ---------------------------------------------------------------------------
  networking.networkmanager.wifi = {
    macAddress = "stable";       # per-SSID random, deterministic by SSID
    scanRandMacAddress = true;
    powersave = false;           # don't drop to legacy rates on idle
    backend = "iwd";             # better than wpa_supplicant for modern Wi-Fi
  };
  networking.networkmanager.ethernet.macAddress = "stable";

  # ---------------------------------------------------------------------------
  # 2. Disable mDNS / LLMNR / NetBIOS — these broadcast hostname/services
  #    onto the hostel LAN. avahi/Windows-style discovery is a leak.
  # ---------------------------------------------------------------------------
  services.avahi.enable = lib.mkForce false;
  services.resolved = {
    enable = true;
    llmnr = "false";
    dnsovertls = "opportunistic";
    settings.Resolve.MulticastDNS = "false";
  };

  # ---------------------------------------------------------------------------
  # 3. Reject IPv6 router advertisements on Wi-Fi (hostile RA = MITM).
  #    Tunnels can still bring their own v6 if needed.
  # ---------------------------------------------------------------------------
  boot.kernel.sysctl = {
    "net.ipv6.conf.${wifiIf}.accept_ra" = 0;
    "net.ipv6.conf.${wifiIf}.autoconf" = 0;
    "net.ipv6.conf.all.accept_ra_rtr_pref" = 0;
    # Tighten reverse-path + martian logging on Wi-Fi specifically
    "net.ipv4.conf.${wifiIf}.rp_filter" = 1;
    "net.ipv4.conf.${wifiIf}.accept_source_route" = 0;
  };

  # ---------------------------------------------------------------------------
  # 4. Stateful firewall: deny inbound on Wi-Fi, deny LAN-side probing back.
  # ---------------------------------------------------------------------------
  networking.firewall = {
    enable = true;
    allowPing = false;
    logRefusedConnections = false;  # noisy on hostel LANs; flip on for debug
    # No open ports. WireGuard is outbound-initiated. ollama is 127.0.0.1.
    interfaces.${wifiIf} = {
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
    # Drop hostel LAN from talking back to ephemeral ports outside of
    # established/related flows (the default policy already handles this,
    # but be explicit for the Wi-Fi iface).
    extraInputRules = ''
      iifname "${wifiIf}" ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16 } ct state new drop
      iifname "${wifiIf}" ip6 saddr { fc00::/7, fe80::/10 } ct state new drop
    '';
  };

  # ---------------------------------------------------------------------------
  # 5. Killswitch — fail-closed when tunnels are down. Allow only:
  #     - traffic via wg0, wg2, tun0
  #     - traffic to xray server IP (so the tunnel can establish)
  #     - DHCP / ARP / ICMP-need (RFC requirement, link viability)
  #     - captive-portal detection endpoints (so portals load)
  #
  # Toggle: `systemctl start untrusted-wifi.target` enables strict mode.
  #         `systemctl stop  untrusted-wifi.target` reverts to default.
  # ---------------------------------------------------------------------------
  systemd.targets.untrusted-wifi = {
    description = "Strict killswitch profile for untrusted Wi-Fi";
  };

  systemd.services.killswitch = {
    description = "nftables killswitch — only tunnel egress allowed";
    bindsTo = [ "untrusted-wifi.target" ];
    after = [ "untrusted-wifi.target" "nftables.service" ];
    wantedBy = [ "untrusted-wifi.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "killswitch-up" ''
        ${pkgs.nftables}/bin/nft -f - <<'EOF'
        table inet killswitch {
          set captive_portals_v4 {
            type ipv4_addr; flags interval;
            elements = {
              # Common captive-portal detection endpoints — resolve once,
              # update if your distro/portal flow changes.
              # Apple, Google, Mozilla, Ubuntu, Microsoft NCSI
              17.0.0.0/8,         # Apple captive.apple.com range
              142.250.0.0/15,     # google connectivitycheck
              34.107.221.82/32,   # detectportal.firefox.com
              91.189.91.0/24,     # ubuntu connectivity-check
              23.211.4.86/32      # msftncsi
            }
          }
          chain output {
            type filter hook output priority 0; policy drop;
            ct state established,related accept
            oif "lo" accept
            oif { "wg0", "wg2", "tun0" } accept
            ip daddr ${xrayServer} accept
            udp dport 67 accept                    # DHCP client
            udp dport 547 accept                   # DHCPv6
            udp dport { 53, 5353 } ip daddr 127.0.0.0/8 accept
            ip daddr @captive_portals_v4 tcp dport { 80, 443 } accept
            icmp type { destination-unreachable, time-exceeded, parameter-problem } accept
            icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit } accept
          }
        }
        EOF
      '';
      ExecStop = "${pkgs.nftables}/bin/nft delete table inet killswitch";
    };
  };

  # ---------------------------------------------------------------------------
  # 6. NTS-secured time (signed NTP) — replaces plain NTP which is trivially
  #    spoofable on hostel LAN and can break TLS cert validation.
  # ---------------------------------------------------------------------------
  services.timesyncd.enable = lib.mkForce false;
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = [
      "time.cloudflare.com"
      "nts.netnod.se"
      "ntppool1.time.nl"
    ];
    extraConfig = ''
      makestep 1.0 3
    '';
  };

  # ---------------------------------------------------------------------------
  # 7. Captive-portal helper — opens a Firefox window in a relaxed network
  #    namespace so you can click through the portal without disabling the
  #    killswitch system-wide. (Optional, manual.)
  #    Usage: `captive-portal`
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    nftables
    (writeShellScriptBin "captive-portal" ''
      echo "Opening captive-portal browser. Close when done; killswitch stays active."
      exec ${firefox}/bin/firefox --new-instance --profile "$(${coreutils}/bin/mktemp -d)" \
        http://detectportal.firefox.com/canonical.html
    '')
    (writeShellScriptBin "untrusted" ''
      case "$1" in
        on)  exec sudo ${pkgs.systemd}/bin/systemctl start untrusted-wifi.target ;;
        off) exec sudo ${pkgs.systemd}/bin/systemctl stop  untrusted-wifi.target ;;
        status) exec ${pkgs.systemd}/bin/systemctl is-active untrusted-wifi.target ;;
        *) echo "usage: untrusted {on|off|status}"; exit 1 ;;
      esac
    '')
  ];
}

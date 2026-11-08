# Xray VLESS + REALITY + post-quantum VLESS Encryption tunnel around DPI that
# throttles WireGuard. Server side (terraform/ansible) lives in the
# dpi-tunnel repo; keys and server in secrets/dpi-tunnel.yaml.
#
# Full tunnel: everything goes via tun1 except what the main table routes
# more specifically than a default (LAN, wg0/wg2 prefixes — their WireGuard
# endpoints then go through the tunnel). Policy rules:
#   999  fwmark -> main         xray's own uplink to the server
#   1000 to <routes> -> 1011    forced prefixes (beat even specific wg* routes)
#   1001 main, suppress /0      specific routes stay where they are
#   1002 -> 1011                everything else
# `systemctl stop dpi-tunnel` removes all of it (back to plain uplink).
{ config, lib, pkgs, utils, ... }:

let
  dev = "tun1";
  table = "1011";
  mark = 4113; # 0x1011
  socksPort = 11081;
  sopsFile = "/etc/nixos/secrets/dpi-tunnel.yaml";
  keys = [ "server" "server_name" "uuid" "short_id" "reality_password" "vless_encryption" "routes" ];
  secret = key: config.sops.secrets."dpi-tunnel/${key}".path;
  ip = "${pkgs.iproute2}/bin/ip";
  jq = lib.getExe pkgs.jq;

  settings = {
    log = { loglevel = "warning"; access = "none"; }; # no per-site journal trail
    inbounds = [
      {
        tag = "tun-in";
        protocol = "tun";
        settings = { name = dev; MTU = 1500; };
      }
      {
        tag = "socks-in";
        listen = "127.0.0.1";
        port = socksPort;
        protocol = "socks";
        settings.udp = true;
      }
    ];
    outbounds = [{
      tag = "proxy";
      protocol = "vless";
      # UDP via XUDP; allow UDP/443 (QUIC, and WireGuard endpoints on 443),
      # which vision rejects by default. TCP stays unmuxed.
      mux = {
        enabled = true;
        concurrency = -1;
        xudpConcurrency = 8;
        xudpProxyUDP443 = "allow";
      };
      settings.vnext = [{
        address = { _secret = secret "server"; };
        port = 443;
        users = [{
          id = { _secret = secret "uuid"; };
          flow = "xtls-rprx-vision";
          encryption = { _secret = secret "vless_encryption"; };
        }];
      }];
      streamSettings = {
        network = "raw";
        security = "reality";
        realitySettings = {
          serverName = { _secret = secret "server_name"; };
          fingerprint = "chrome";
          password = { _secret = secret "reality_password"; };
          shortId = { _secret = secret "short_id"; };
        };
        # Marked so rule 999 keeps the uplink off tun1 (no loop).
        sockopt.mark = mark;
      };
    }];
  };
in
{
  sops.secrets = lib.genAttrs (map (k: "dpi-tunnel/${k}") keys) (name: {
    inherit sopsFile;
    key = lib.removePrefix "dpi-tunnel/" name;
    restartUnits = [ "dpi-tunnel.service" ];
  });

  systemd.services.dpi-tunnel = {
    description = "Xray VLESS Reality PQ client";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    preStart = utils.genJqSecretsReplacementSnippet settings "/run/dpi-tunnel/config.json";
    postStart = ''
      for _ in $(seq 50); do [ -e /sys/class/net/${dev} ] && break; sleep 0.1; done
      ${ip} link set ${dev} up
      for v in -4 -6; do
        ${ip} $v route replace default dev ${dev} table ${table}
        ${ip} $v rule add fwmark ${toString mark} lookup main priority 999
        ${ip} $v rule add lookup main suppress_prefixlength 0 priority 1001
        ${ip} $v rule add lookup ${table} priority 1002
      done
      for cidr in $(${jq} -r '.[]' ${secret "routes"}); do
        ${ip} route replace "$cidr" dev ${dev} table ${table}
        ${ip} rule add to "$cidr" lookup ${table} priority 1000
      done
    '';
    postStop = ''
      for v in -4 -6; do
        for p in 999 1000 1001 1002; do
          while ${ip} $v rule del priority $p 2>/dev/null; do :; done
        done
        ${ip} $v route flush table ${table} 2>/dev/null || true
      done
    '';
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.xray} run -c /run/dpi-tunnel/config.json";
      RuntimeDirectory = "dpi-tunnel";
      RuntimeDirectoryMode = "0700";
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Xray keeps tun UDP sessions alive while packets arrive, so a WireGuard
  # keepalive pins a session whose mux link died (suspend, Wi-Fi loss)
  # forever. Start clean after resume and on every new uplink.
  systemd.services.dpi-tunnel-resume = rec {
    description = "Restart dpi-tunnel after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
    wantedBy = after;
    serviceConfig.Type = "oneshot";
    script = "systemctl try-restart dpi-tunnel.service";
  };

  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeShellScript "dpi-tunnel-uplink" ''
      case "$1" in lo|wg*|tun*|docker*|br-*|veth*|virbr*) exit 0 ;; esac
      [ "$2" = up ] && systemctl try-restart dpi-tunnel.service
      exit 0
    '';
  }];
}

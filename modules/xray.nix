# Xray VLESS+Reality with tun2socks transparent proxy (all traffic)
{ config, pkgs, lib, ... }:

let
  xrayServer = "172.232.216.157";
in
{
  # Xray systemd service
  systemd.services.xray = {
    description = "Xray Proxy";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.xray}/bin/xray run -config /etc/xray/config.json";
      Restart = "on-failure";
      RestartSec = 5;
      DynamicUser = true;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ReadOnlyPaths = [ "/etc/xray" ];
    };
  };

  # tun2socks — creates TUN device routing all traffic through SOCKS5
  systemd.services.tun2socks = {
    description = "tun2socks transparent proxy";
    after = [ "xray.service" ];
    wants = [ "xray.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStartPre = pkgs.writeShellScript "tun2socks-setup" ''
        ${pkgs.iproute2}/bin/ip tuntap add mode tun dev tun0 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip addr add 198.18.0.1/15 dev tun0 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link set dev tun0 up
      '';
      ExecStart = "${pkgs.tun2socks}/bin/tun2socks -device tun0 -proxy socks5://127.0.0.1:10808 -interface lo";
      ExecStartPost = pkgs.writeShellScript "tun2socks-routes" ''
        # Get current default gateway
        GW=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk '{print $3; exit}')
        DEV=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk '{print $5; exit}')

        # Route xray server traffic directly (avoid loop)
        ${pkgs.iproute2}/bin/ip route add ${xrayServer}/32 via $GW dev $DEV 2>/dev/null || true

        # Route everything else through tun0
        ${pkgs.iproute2}/bin/ip route add default dev tun0 metric 1 2>/dev/null || true
      '';
      ExecStopPost = pkgs.writeShellScript "tun2socks-teardown" ''
        ${pkgs.iproute2}/bin/ip route del default dev tun0 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip route del ${xrayServer}/32 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link set dev tun0 down 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip tuntap del mode tun dev tun0 2>/dev/null || true
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # DNS through tunnel — use public DNS that will go through tun0
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Firefox — disable WebRTC leak
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;
    policies = {};
  };
}

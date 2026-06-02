# Xray VLESS+Reality (PQ encryption) with sing-box TUN
{ config, pkgs, lib, ... }:

let
  private = import ./private/xray-routes.nix;
  xrayServer = private.xrayServer;
in
{
  # Xray — VLESS+Reality with post-quantum encryption
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

  # sing-box — TUN mode forwarding to xray's SOCKS5
  services.sing-box = {
    enable = true;
    settings = {
      log.level = "warn";

      inbounds = [{
        type = "tun";
        tag = "tun-in";
        interface_name = "tun0";
        address = [ "198.18.0.1/15" "fdfe:dcba:9876::1/126" ];
        auto_route = true;
        strict_route = true;
        route_exclude_address = [ "${xrayServer}/32" ] ++ private.routeExcludeAddress;
        stack = "gvisor";
      }];

      outbounds = [
        {
          type = "socks";
          tag = "xray";
          server = "127.0.0.1";
          server_port = 10808;
          udp_over_tcp = false;
        }
        {
          type = "direct";
          tag = "direct";
        }
      ];

      dns = {
        servers = [
          {
            tag = "doh-proxy";
            type = "https";
            server = "1.1.1.1";
            detour = "xray";
          }
          {
            tag = "direct-dns";
            type = "local";
          }
        ];
      };

      route = {
        auto_detect_interface = true;
        default_domain_resolver = "doh-proxy";
        rules = [
          {
            action = "sniff";
          }
          {
            protocol = "dns";
            action = "hijack-dns";
          }
          {
            action = "route";
            outbound = "direct";
            ip_cidr = [ "${xrayServer}/32" ];
          }
          {
            action = "route";
            outbound = "direct";
            ip_cidr = [
              "127.0.0.0/8"
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
            ];
          }
        ];
      };
    };
  };

  # sing-box needs NET_ADMIN for TUN
  systemd.services.sing-box.serviceConfig = {
    AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
    CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" ];
  };

  # Firefox dev edition
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;
    policies = {
      # Estonian ID: load OpenSC PKCS#11 for TLS client-cert auth,
      # and force-install the Web eID extension (talks to web-eid-app host).
      SecurityDevices.OpenSC = "${pkgs.opensc}/lib/opensc-pkcs11.so";
      ExtensionSettings."{e68418bc-f2b0-4459-a9ea-1a5d2b75d8e9}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/web-eid-webextension/latest.xpi";
        installation_mode = "force_installed";
      };
    };
  };
}

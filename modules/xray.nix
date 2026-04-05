# Xray VLESS+Reality proxy with system-wide proxy settings
{ config, pkgs, lib, ... }:

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
      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ReadOnlyPaths = [ "/etc/xray" ];
    };
  };

  # System-wide proxy environment variables
  networking.proxy = {
    default = "http://127.0.0.1:10809";
    noProxy = "127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
  };

  # Firefox proxy via enterprise policy
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;
    policies = {
      Proxy = {
        Mode = "manual";
        SOCKSProxy = "127.0.0.1:10808";
        SOCKSVersion = 5;
        Passthrough = "127.0.0.1,localhost";
        UseProxyForDNS = true;
      };
    };
  };

  # GNOME proxy settings via dconf
  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/system/proxy" = {
      mode = "manual";
    };
    settings."org/gnome/system/proxy/http" = {
      host = "127.0.0.1";
      port = lib.gvariant.mkUint32 10809;
    };
    settings."org/gnome/system/proxy/https" = {
      host = "127.0.0.1";
      port = lib.gvariant.mkUint32 10809;
    };
    settings."org/gnome/system/proxy/socks" = {
      host = "127.0.0.1";
      port = lib.gvariant.mkUint32 10808;
    };
  }];
}

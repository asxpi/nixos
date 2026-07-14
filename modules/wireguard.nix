# WireGuard VPN configuration
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  sops.secrets = {
    "wg0.conf" = {
      sopsFile = "/etc/nixos/secrets/wg0.conf";
      format = "binary";
      restartUnits = [ "wg-quick-wg0.service" ];
    };
    "wg2.conf" = {
      sopsFile = "/etc/nixos/secrets/wg2.conf";
      format = "binary";
      restartUnits = [ "wg-quick-wg2.service" ];
    };
  };

  # WireGuard interface
  networking.wg-quick.interfaces = {
    wg0 = {
      configFile = config.sops.secrets."wg0.conf".path;
      autostart = true;
    };
    wg2 = {
      configFile = config.sops.secrets."wg2.conf".path;
      autostart = true;
    };
  };
}

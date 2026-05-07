# WireGuard VPN configuration
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  # WireGuard interface
  networking.wg-quick.interfaces = {
    wg0 = {
      configFile = "/etc/wireguard/wg0.conf"; # TODO: Secret Manager. TODO: Add SSH, GPG as well to secret manager
      autostart = true;
    };
    wg2 = {
      configFile = "/etc/wireguard/wg2.conf";
      autostart = true;
    };
  };
}

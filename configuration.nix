# NixOS Configuration
# Main entry point - imports modular configuration files
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/boot.nix
    ./modules/networking.nix
    ./modules/locale.nix
    ./modules/desktop.nix
    ./modules/users.nix
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/programs.nix
    ./modules/wireguard.nix
    ./modules/security.nix
    ./modules/sops.nix
    ./modules/power.nix
    ./modules/xray.nix
    ./modules/ollama.nix
    ./modules/lemonade.nix
    ./modules/gaming.nix
    ./modules/litecoin.nix
    # ./modules/hostel-wifi.nix  # disabled 2026-05-08 — re-enable when needed
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).

  system.stateVersion = "25.11";
}

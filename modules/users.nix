# User accounts configuration
{ config, pkgs, lib, ... }:

{
  # Enable passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.asxpi = {
    isNormalUser = true;
    description = "Sergei P";
    extraGroups = [ "networkmanager" "wheel" "dialout" "libvirtd" "podman" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      # Internet
      thunderbird
      telegram-desktop
      firefox-devedition
      # Music
      tidal-hifi
      # Discord
      discord-ptb
      # Code
      zed-editor
      # Media
      qbittorrent
      mpv
      # Games
      runelite
      # bolt-launcher
      # Utils
      cameractrls
      # Notes
      obsidian
    ];
  };
}

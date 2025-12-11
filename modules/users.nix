# User accounts configuration
{ config, pkgs, lib, ... }:

{
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.asxpi = {
    isNormalUser = true;
    description = "Sergei P";
    extraGroups = [ "networkmanager" "wheel" "dialout" ];
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
    ];
  };
}

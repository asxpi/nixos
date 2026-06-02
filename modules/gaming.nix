# Gaming-related configuration
# Flatpak is managed declaratively via nix-flatpak (see flake.nix input).
{ config, pkgs, lib, ... }:

{
  # Proton-GE for Steam (better Jagex Launcher compatibility than stock Proton).
  # Steam itself is enabled in modules/programs.nix.
  programs.steam.extraCompatPackages = [ pkgs.proton-ge-bin ];

  services.flatpak = {
    enable = true;
    remotes = [
      { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
    ];
    packages = [
      # Bolt: Jagex-account launcher for RuneScape 3 (NXT) and OSRS / RuneLite.
      { appId = "com.adamcake.Bolt"; origin = "flathub"; }
      # Sober: Roblox Player runtime (Android build via Flatpak) — no native Linux client.
      { appId = "org.vinegarhq.Sober"; origin = "flathub"; }
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}

# Desktop environment, display, and audio configuration
{ config, pkgs, lib, ... }:

{
  # AMD GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For Steam/Wine
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Let systemd-logind own all sleep/idle policy. gsd-power otherwise
  # second-guesses suspend-then-hibernate and re-wakes the machine before
  # HibernateDelaySec elapses (observed on P14s G6 AMD). Set via dconf
  # system db (gsettings-overrides only compiles desktop/shell/mutter
  # schemas, so a g-s-d plugin override there is silently dropped).
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-battery-type = "nothing";
        sleep-inactive-ac-type = "nothing";
        power-button-action = "nothing";
      };
    };
  }];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "grp:alt_shift_toggle";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
}

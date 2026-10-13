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

  # gnome-shell segfaults in touch_can_grab_surface() when a client asks for
  # a move/resize grab with the serial of a cancelled touch (NULL
  # focus_surface). Not fixed upstream as of mutter 50.2 / main 2026-10-13.
  # Drop once nixpkgs' mutter carries a fix.
  nixpkgs.overlays = [
    (final: prev: {
      mutter = prev.mutter.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../patches/mutter-touch-cancelled-grab.patch ];
      });
    })
  ];

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

  # P14s G6 AMD: the F4 mic-mute LED (platform::micmute) is driven by the
  # kernel's `audio-micmute` trigger, which follows the HD-audio codec's
  # hardware capture-mute. PipeWire mutes in software at the node level and
  # never touches that codec mute, so the trigger reports "muted" (LED lit)
  # permanently while the mic actually works. Detach the trigger and force
  # the LED off at boot. Verified: writing brightness=0 clears it, so the EC
  # is fine — this is purely a trigger/software-mute mismatch.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="platform::micmute", ATTR{trigger}="none", ATTR{brightness}="0"
  '';
}

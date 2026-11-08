# Power management — ThinkPad P14s Gen 6 (AMD)
{ config, pkgs, lib, ... }:

{
  # AMD P-State driver (active mode for full EPP control)
  # acpi.ec_no_wakeup=1: prevents EC wakeups from draining battery in s2idle
  # on P14s G6 AMD. See https://lore.kernel.org/all/ZnFYpWHJ5Ml724Nv@ohnotp/
  boot.kernelParams = [ "amd_pstate=active" "acpi.ec_no_wakeup=1" ];

  # Allow manual fan control via /proc/acpi/ibm/fan (level 0-7, auto,
  # full-speed). Firmware stays in charge while level is "auto".
  boot.extraModprobeConfig = "options thinkpad_acpi fan_control=1";

  # Hibernate disabled: the disk swapfile was removed (it was the resume
  # target). To restore: re-add swapDevices, boot.resumeDevice,
  # resume_offset (filefrag -v /var/swapfile) and the *-hibernate actions.

  # zram only, capped at 8 GiB so it can't eat into memory needed for large
  # LLM/GTT loads. memoryMax caps the 50% default (~30 GiB).
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    memoryMax = 8 * 1024 * 1024 * 1024;
    priority = 100;
  };

  # Without swap, hibernate is unavailable: plain s2idle suspend everywhere.
  # Caveat: plain suspend once let a spurious-wake loop run for 1.5 days on
  # AC (logind re-suspends every 30s with the lid closed); there's no longer
  # a hibernate fallback to end it. acpi.ec_no_wakeup=1 + gsd-power dconf
  # tweaks (desktop.nix) are what keep s2idle stable.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleSuspendKey = "suspend";
    HandlePowerKey = "poweroff";
    IdleAction = "suspend";
    IdleActionSec = "30min";
  };

  # Stop USB devices (e.g. Aerox 3 WL receiver) from waking the machine
  # from s2idle. Only usb_device nodes have power/wakeup; matching on the
  # devtype avoids "Invalid operator for ATTRS" on udev verification.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{power/wakeup}="disabled"
  '';

  # CPU frequency scaling
  powerManagement.cpuFreqGovernor = "powersave";

  # Disable power-profiles-daemon (conflicts with TLP)
  services.power-profiles-daemon.enable = false;

  # TLP — settings owned by the TLP Profile Switcher GNOME extension.
  # The extension does `pkexec cp ~/.tlp/<profile>.conf /etc/tlp.conf`, but
  # NixOS makes /etc/tlp.conf a read-only symlink into the Nix store. We
  # replace the symlink with a writable copy on every activation, AND if
  # one of the user's ~/.tlp/*.conf matches the previous /etc/tlp.conf
  # (= the user picked it from the panel), restore that one instead of the
  # NixOS stub. This way the chosen profile survives nixos-rebuild switch.
  services.tlp.enable = true;
  system.activationScripts.tlpWritable = lib.stringAfter [ "etc" ] ''
    profilesDir=/home/asxpi/.tlp
    target=/etc/tlp.conf
    activeMarker=/var/lib/tlp-active-profile

    # If the current file matches one of the user's profiles, remember it
    # before NixOS replaces the symlink target.
    if [ -f "$target" ] && [ ! -L "$target" ] && [ -d "$profilesDir" ]; then
      currentSum=$(${pkgs.coreutils}/bin/sha256sum "$target" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
      for p in "$profilesDir"/*.conf; do
        [ -f "$p" ] || continue
        s=$(${pkgs.coreutils}/bin/sha256sum "$p" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
        if [ "$s" = "$currentSum" ]; then
          ${pkgs.coreutils}/bin/basename "$p" .conf > "$activeMarker"
          break
        fi
      done
    fi

    # Replace the read-only symlink with a writable real file.
    if [ -L "$target" ]; then
      cp --remove-destination "$(readlink -f "$target")" "$target"
      chmod 0644 "$target"
    fi

    # If we previously remembered an active profile, restore it.
    if [ -f "$activeMarker" ]; then
      active=$(cat "$activeMarker")
      if [ -f "$profilesDir/$active.conf" ]; then
        cp "$profilesDir/$active.conf" "$target"
        chmod 0644 "$target"
      fi
    fi
  '';

  # Hook the extension's cp: whenever /etc/tlp.conf changes via the panel,
  # also update the marker. systemd.path watches the file mtime.
  systemd.paths.tlp-active-profile-tracker = {
    description = "Track which TLP profile is currently active";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = "/etc/tlp.conf";
      Unit = "tlp-active-profile-tracker.service";
    };
  };
  systemd.services.tlp-active-profile-tracker = {
    description = "Update /var/lib/tlp-active-profile to match /etc/tlp.conf";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "tlp-track" ''
        profilesDir=/home/asxpi/.tlp
        target=/etc/tlp.conf
        marker=/var/lib/tlp-active-profile
        [ -f "$target" ] || exit 0
        [ -d "$profilesDir" ] || exit 0
        currentSum=$(${pkgs.coreutils}/bin/sha256sum "$target" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
        for p in "$profilesDir"/*.conf; do
          [ -f "$p" ] || continue
          s=$(${pkgs.coreutils}/bin/sha256sum "$p" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
          if [ "$s" = "$currentSum" ]; then
            ${pkgs.coreutils}/bin/basename "$p" .conf > "$marker"
            exit 0
          fi
        done
      '';
    };
  };

  # Bluetooth off at boot
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      ControllerMode = "dual";
      FastConnectable = true;
      JustWorksRepairing = "always";
      Privacy = "device";
      Experimental = true;
    };
  };

  # Battery monitoring
  services.upower.enable = true;

  # powertop for diagnostics
  environment.systemPackages = [ pkgs.powertop ];
}

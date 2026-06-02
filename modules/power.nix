# Power management — ThinkPad P14s Gen 6 (AMD)
{ config, pkgs, lib, ... }:

{
  # AMD P-State driver (active mode for full EPP control)
  # resume_offset = first physical block of /var/swapfile (for hibernate from
  # an ext4 swapfile on LUKS). Recompute if the swapfile is recreated:
  #   sudo filefrag -v /var/swapfile | awk 'NR==4{gsub(/\.\./,""); print $4}'
  # acpi.ec_no_wakeup=1: prevents EC wakeups from draining battery in s2idle
  # on P14s G6 AMD. See https://lore.kernel.org/all/ZnFYpWHJ5Ml724Nv@ohnotp/
  boot.kernelParams = [ "amd_pstate=active" "resume_offset=1769472" "acpi.ec_no_wakeup=1" ];

  # Hibernate / resume from encrypted swapfile on LUKS root.
  # P14s G6 AMD has no S3 (Modern Standby only); this enables
  # suspend-then-hibernate so long sleeps drain to disk.
  boot.resumeDevice = "/dev/mapper/luks-71c97ce7-dd29-4b07-8d2a-8cc3985a65bd";

  # On battery: suspend-then-hibernate (s2idle then hibernate after
  # HibernateDelaySec). Previously this looped suspend->wake->suspend due
  # to ACPI EC interrupts, but acpi.ec_no_wakeup=1 (above) plus disabling
  # gsd-power's sleep handlers (in desktop.nix via dconf) makes it stable.
  # On AC, plain suspend (s2idle) is fine.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
    HandleSuspendKey = "suspend-then-hibernate";
    HandlePowerKey = "hibernate";
    IdleAction = "suspend-then-hibernate";
    IdleActionSec = "30min";
  };

  # s2idle window before transitioning to hibernate. acpi.ec_no_wakeup=1
  # (above) prevents the prior EC-driven s2idle thrash on this machine.
  # Conservative value while bag-thermal behavior is being re-validated;
  # raise to 30-45min once confirmed safe.
  systemd.sleep.settings.Sleep.HibernateDelaySec = "15min";

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

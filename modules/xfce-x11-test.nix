# A second boot entry, "xfce-x11", that looks like hx26's desktop for the
# another.im typing-jitter bug (2026-10-19): Xfce on Xorg with xfwm4
# compositing, logged in through LightDM. Only the display manager and the
# session differ from the default entry; GNOME stays installed, so the
# normal boot is untouched. Pick the entry in the boot menu.
{ lib, ... }:

{
  specialisation.xfce-x11.configuration = {
    system.nixos.tags = [ "xfce-x11" ];

    # GDM in GNOME 50 no longer starts Xorg sessions.
    services.displayManager.gdm.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = true;

    services.xserver.desktopManager.xfce.enable = true;
    services.displayManager.defaultSession = lib.mkForce "xfce";
  };
}

# Bootloader and Secure Boot configuration
{ config, pkgs, lib, ... }:

{
  # Use latest kernel instead of LTS
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # Note: security.nix forces hardened kernel, so we use that.

  # Lanzaboote Secure Boot
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.loader.efi.canTouchEfiVariables = true;

  /* GRUB disabled for Secure Boot (Lanzaboote)
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    extraEntries = ''
      menuentry "Arch Linux (default)" {
        search --set=root --fs-uuid 15ae8384-3dfc-4915-9201-66ecfc5f230d
        linux /@/boot/vmlinuz-linux root=UUID=15ae8384-3dfc-4915-9201-66ecfc5f230d rootflags=subvol=@ rw
        initrd /@/boot/initramfs-linux.img
      }
    '';
  };
  */
}

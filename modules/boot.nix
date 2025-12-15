# Bootloader and GRUB configuration
{ config, pkgs, lib, ... }:

{
  # boot.loader.systemd-boot.enable = true; # Disabled for GRUB
  boot.loader.efi.canTouchEfiVariables = true;

  # GRUB bootloader
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    # useOSProber = true;
    # extraConfig = "GRUB_DISABLE_OS_PROBER=false";
    extraEntries = ''
      menuentry "Arch Linux (default)" {
        search --set=root --fs-uuid 15ae8384-3dfc-4915-9201-66ecfc5f230d
        linux /@/boot/vmlinuz-linux root=UUID=15ae8384-3dfc-4915-9201-66ecfc5f230d rootflags=subvol=@ rw
        initrd /@/boot/initramfs-linux.img
      }

      menuentry "Arch Linux (zen)" {
        search --set=root --fs-uuid 15ae8384-3dfc-4915-9201-66ecfc5f230d
        linux /@/boot/vmlinuz-linux-zen root=UUID=15ae8384-3dfc-4915-9201-66ecfc5f230d rootflags=subvol=@ rw
        initrd /@/boot/initramfs-linux-zen.img
      }

      menuentry "Arch Linux (lts)" {
        search --set=root --fs-uuid 15ae8384-3dfc-4915-9201-66ecfc5f230d
        linux /@/boot/vmlinuz-linux-lts root=UUID=15ae8384-3dfc-4915-9201-66ecfc5f230d rootflags=subvol=@ rw
        initrd /@/boot/initramfs-linux-lts.img
      }
    '';
  };
}

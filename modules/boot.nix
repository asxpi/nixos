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

  # Arch Linux systemd-boot entry
  # Copies kernel/initramfs from Arch btrfs partition to ESP and creates loader entry
  system.activationScripts.archBoot = let
    archEntry = pkgs.writeText "arch.conf" ''
      title   Arch Linux
      linux   /arch/vmlinuz-linux
      initrd  /arch/initramfs-linux.img
      options root=UUID=15ae8384-3dfc-4915-9201-66ecfc5f230d rootflags=subvol=@ rw
    '';
  in ''
    mkdir -p /boot/arch
    if mountpoint -q /mnt/arch; then
      cp /mnt/arch/boot/vmlinuz-linux /boot/arch/vmlinuz-linux
      cp /mnt/arch/boot/initramfs-linux.img /boot/arch/initramfs-linux.img
      ${pkgs.sbctl}/bin/sbctl sign /boot/arch/vmlinuz-linux
    fi
    mkdir -p /boot/loader/entries
    cp ${archEntry} /boot/loader/entries/arch.conf
  '';
}

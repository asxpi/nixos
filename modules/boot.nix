# Bootloader and Secure Boot configuration
{ config, pkgs, lib, ... }:

{
  # Kernel 7.x: the in-tree amdxdna driver on 6.18 is too old for FastFlowLM
  # (flm validate: kernel_ok=false, and it loads NPU firmware 1.0.0.63 while
  # FLM needs >=1.1.0.0 — the 7.x driver loads npu_7.sbin = 1.1.2.64 instead).
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # amdgpu GTT (dynamically shared system RAM the iGPU can address) raised to
  # 56 GiB. On kernel 6.18 `amdgpu.gttsize` is deprecated; TTM controls it in
  # 4 KiB pages: 56 GiB / 4 KiB = 14680064. Pair with a shrunken BIOS UMA/VRAM
  # carve-out (set to 1-2GB in UEFI; VRAM peak observed is ~2.5G and buffers
  # spill to GTT) so ~60GB system RAM backs this pool — GTT is reclaimable,
  # only consumed when the GPU actually touches it.
  # Merges with boot.kernelParams in power.nix (list options are concatenated).
  # Verify after reboot: cat /sys/class/drm/card*/device/mem_info_gtt_total
  boot.kernelParams = [
    "ttm.pages_limit=14680064"
    "ttm.page_pool_size=14680064"
  ];

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

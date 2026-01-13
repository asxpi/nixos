{ config, pkgs, lib, ... }:

{
  imports = [
    ./usb-devices.nix
  ];

  # Use the hardened kernel for better security
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_hardened;

  # Only allow members of the wheel group to execute sudo
  security.sudo.execWheelOnly = true;

  # Linux Audit Framework
  security.auditd.enable = true;
  security.audit.enable = true;

  # Kernel Hardening
  security.protectKernelImage = true;

  # Sysctl hardening
  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 1;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
  };

  # USBGuard configuration
  services.usbguard = {
    enable = true;
    dbus.enable = true;
    implicitPolicyTarget = "block";
  };
}

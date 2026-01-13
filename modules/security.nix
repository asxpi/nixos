{ config, pkgs, ... }:

{
  # Only allow members of the wheel group to execute sudo
  security.sudo.execWheelOnly = true;

  # Linux Audit Framework (suggested by Lynis)
  security.auditd.enable = true;
  security.audit.enable = true;

  # Kernel Hardening
  security.protectKernelImage = true;

  # Sysctl hardening
  boot.kernel.sysctl = {
    # Hide kernel pointers from unprivileged users
    "kernel.kptr_restrict" = 1;

    # Restrict ptrace to only child processes
    "kernel.yama.ptrace_scope" = 1;

    # Disable BPF JIT for unprivileged users
    "kernel.unprivileged_bpf_disabled" = 1;

    # Networking hardening
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
  };
}

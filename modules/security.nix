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
  security.audit.rules = [
    "-a exit,always -F arch=b64 -S execve"
    "-w /etc/passwd -p wa -k passwd_changes"
    "-w /etc/shadow -p wa -k shadow_changes"
  ];

  # Kernel Hardening
  security.protectKernelImage = true;

  # Sysctl hardening
  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.sysrq" = 0;
    "kernel.unprivileged_userns_clone" = 1; # Required for rootless Podman
    "kernel.yama.ptrace_scope" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
  };

  # USBGuard configuration
  services.usbguard = {
    enable = true;
    dbus.enable = true;
    implicitPolicyTarget = "block";
  };

  # OpenSnitch Application Firewall
  services.opensnitch.enable = true;

  security.pam.loginLimits = [
    { domain = "*"; item = "core"; type = "-"; value = "0"; }
  ];

  systemd.services.systemd-udevd.serviceConfig = {
    PrivateNetwork = true;
    RestrictAddressFamilies = "AF_UNIX AF_NETLINK";
  };

  # Podman socket for all users
  systemd.user.sockets.podman.wantedBy = [ "sockets.target" ];

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true; # System-wide /var/run/docker.sock symlink
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };

  virtualisation.docker.enable = lib.mkForce false;

  # Set DOCKER_HOST to point to the user rootless socket automatically
  environment.extraInit = ''
    if [ -z "$DOCKER_HOST" -a -S "/run/user/$(id -u)/podman/podman.sock" ]; then
      export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    fi
  '';

  environment.systemPackages = with pkgs; [
    lynis
    audit
    tcpdump
    bandwhich
    opensnitch-ui
  ];
}

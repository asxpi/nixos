# Programs and services configuration
{ config, pkgs, lib, ... }:

{
  # GPG agent
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  # Git configuration
  environment.etc."gitconfig".text = ''
    [user]
      name = Sergei Poljanski
      email = me@asxp.io
      signingkey = 4F8851660FA4121B
    [commit]
      gpgsign = true
    [init]
      defaultBranch = main
    [safe]
      directory = /etc/nixos
  '';

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Steam gaming platform
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
  ];

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable fwupd service
  services.fwupd.enable = true;

  # Virtualization (KVM/QEMU)
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
}

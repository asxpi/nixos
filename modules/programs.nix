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

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
}

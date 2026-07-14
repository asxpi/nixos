# sops-nix: decrypt secrets at activation using the root-side age key.
# Key installed once via:
#   sudo install -d -m 700 /var/lib/sops-nix
#   sudo install -m 600 ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
{ config, pkgs, ... }:

{
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Secret files are gitignored (only .example structure files are tracked),
  # so they are referenced by absolute path and read at activation, not eval.
  sops.validateSopsFiles = false;

  # SSH keys travel as one encrypted tarball so filenames stay inside the
  # encrypted payload. (Re)create with:
  #   tar -C ~/.ssh -cf secrets/ssh-keys.tar <keys...> && sops -e -i secrets/ssh-keys.tar
  sops.secrets."ssh-keys.tar" = {
    sopsFile = "/etc/nixos/secrets/ssh-keys.tar";
    format = "binary";
  };
  system.activationScripts.ssh-keys = {
    deps = [ "setupSecrets" "users" ];
    text = ''
      mkdir -p /home/asxpi/.ssh
      ${pkgs.gnutar}/bin/tar --unlink-first -C /home/asxpi/.ssh -xf ${config.sops.secrets."ssh-keys.tar".path}
      chown -R asxpi:users /home/asxpi/.ssh
      chmod 700 /home/asxpi/.ssh
    '';
  };
}

# Litecoin Core 0.21.5.5 (MWEB) — vendored build, revives the package dropped
# from nixpkgs. Builds against openssl_3 + boost181 (older Boost's autotools
# ax_boost macros are needed; Boost 1.89 fails the Boost::System link probe).
{ config, pkgs, lib, ... }:

let
  litecoin = pkgs.libsForQt5.callPackage ./litecoin-pkg.nix {
    openssl = pkgs.openssl_3;
    boost = pkgs.boost181;
  };
in
{
  environment.systemPackages = [ litecoin ];
}

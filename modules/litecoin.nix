# Litecoin Core v0.21.4 - full node wallet
{ config, pkgs, lib, ... }:

let
  litecoin-core = pkgs.stdenv.mkDerivation rec {
    pname = "litecoin-core";
    version = "0.21.4";

    src = pkgs.fetchurl {
      url = "https://download.litecoin.org/litecoin-${version}/linux/litecoin-${version}-x86_64-linux-gnu.tar.gz";
      hash = "sha256-hX/EEJHyuuZcO/D9TTiPypFfyToD8W3SV4rDzJKJg5A=";
    };

    sourceRoot = ".";

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      fontconfig
      freetype
      xorg.libxcb
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp litecoin-${version}/bin/* $out/bin/
    '';
  };
in
{
  environment.systemPackages = [ litecoin-core ];
}

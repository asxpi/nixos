{ lib, stdenv, mkDerivation, fetchFromGitHub
, pkg-config, autoreconfHook
, openssl, db48, boost, zlib
, glib, protobuf, util-linux, qrencode, sqlite
, withGui ? true, libevent
, qtbase, qttools
, zeromq
, fmt
}:

# Litecoin Core 0.21.5.5 (MWEB). Revives the package dropped from nixpkgs in
# 2024-11 (commit 0367571). Build system is autotools (unlike modern Bitcoin
# Core, which moved to CMake). Still links OpenSSL — built against openssl_3
# here (passed in by litecoin.nix), not the insecure 1.1 the old pin used.
mkDerivation rec {
  pname = "litecoin" + lib.optionalString (!withGui) "d";
  version = "0.21.5.5";

  src = fetchFromGitHub {
    owner = "litecoin-project";
    repo = "litecoin";
    rev = "v${version}";
    hash = "sha256-lGWZ8SVa4depLXr/TJvk2G/sAbK/bVvHAnaN83XfIbA=";
  };

  patches = [ ];

  nativeBuildInputs = [ pkg-config autoreconfHook ];

  buildInputs = [ openssl db48 boost zlib zeromq fmt
                  glib protobuf util-linux libevent sqlite ]
                ++ lib.optionals withGui [ qtbase qttools qrencode ];

  # UPnP disabled: 0.21.5.5 predates the miniupnpc 2.2.8 API change
  # (UPNP_GetValidIGD signature); auto-opening firewall ports is unwanted
  # exposure anyway. Drops the miniupnpc dependency entirely.
  configureFlags = [
    "--with-boost-libdir=${boost.out}/lib"
    "--with-sqlite=yes"
    "--without-miniupnpc"
  ] ++ lib.optionals withGui [
    "--with-gui=qt5"
    "--with-qt-bindir=${qtbase.dev}/bin:${qttools.dev}/bin"
  ];

  enableParallelBuilding = true;
  doCheck = false;

  meta = with lib; {
    description = "Peer-to-peer cryptocurrency (Litecoin Core ${version}, with MWEB)";
    homepage = "https://litecoin.org/";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = if withGui then "litecoin-qt" else "litecoind";
    maintainers = with maintainers; [ ];
  };
}

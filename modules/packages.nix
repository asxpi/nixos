# System packages configuration
{ config, pkgs, lib, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "castlabs-electron"
    "tidal-hifi"
    "discord-ptb"
  ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    # Core utilities
    nano
    git
    curl
    wget
    htop
    fastfetch
    ncdu
    file
    tree
    unzip
    zip
    rsync

    # Modern CLI replacements
    ripgrep     # rg - faster grep
    fd          # faster find
    bat         # better cat with syntax highlighting
    eza         # better ls (exa replacement)
    duf         # better df
    jq          # JSON processor

    # Hardware & system info
    pciutils    # lspci
    usbutils    # lsusb
    lsof        # list open files
    iotop       # disk I/O monitor

    # Networking tools
    net-tools   # netstat, ifconfig (legacy)
    iproute2    # ss, ip (modern)
    dnsutils    # dig, nslookup
    traceroute
    nmap        # network scanner

    # Filesystem
    os-prober
    btrfs-progs

    # Development
    nodejs_20
    gnupg

    # WWAN modem tools
    libmbim
    libqmi
    modemmanager
  ];
}

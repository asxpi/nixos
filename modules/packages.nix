# System packages configuration
{ config, pkgs, lib, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "castlabs-electron"
    "tidal-hifi"
    "discord-ptb"
    "steam"
    "steam-original"
    "steam-unwrapped"
    "steam-run"
    "terraform"
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
    smartmontools # smartctl
    nvme-cli    # nvme

    # Networking tools
    net-tools   # netstat, ifconfig (legacy)
    iproute2    # ss, ip (modern)
    dnsutils    # dig, nslookup
    traceroute
    nmap        # network scanner

    # Filesystem
    os-prober
    btrfs-progs
    gparted

    # Development
    nodejs_20
    gnupg

    # Automation / Cloud tools
    ansible
    ansible-lint
    sshpass         # for ansible password authentication
    terraform
    opentofu        # open-source Terraform fork
    kubectl
    kubernetes-helm # helm
    k9s             # Kubernetes TUI
    awscli2
    # azure-cli
    google-cloud-sdk
    docker-compose
    argocd
    fluxcd
    kubectx         # switch between contexts/namespaces
    stern           # multi-pod log tailing

    # WWAN modem tools
    libmbim
    libqmi
    modemmanager

    # Estonian ID / digital signature
    qdigidoc

    # Privacy / Anonymity
    tor-browser
    ivpn
    ivpn-service
    ivpn-ui
  ];
}

# System packages configuration
{ config, pkgs, lib, inputs, ... }:

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
    "packer"
    "obsidian"
    "hyperplay-ext"
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
    sbctl
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

    # Desktop / GUI Apps
    gnome-tweaks
    obs-studio
    inputs.anotherim.packages.${pkgs.system}.default

    # Gaming
    heroic

    # Development
    nodejs_20
    gnupg
    go
    python3
    sqlite
    sqlitebrowser

    # Minecraft
    jdk21_headless

    # Automation / Cloud tools
    sops
    age
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
    podman-compose
    # argocd # broken in nixpkgs 2026-02-13
    fluxcd
    kubectx         # switch between contexts/namespaces
    stern           # multi-pod log tailing
    hcloud          # Hetzner Cloud CLI
    packer          # image builder
    talosctl        # Talos OS CLI
    eksctl          # AWS EKS CLI
    # terragrunt    # broken in nixpkgs
    gh

    # WWAN modem tools
    libmbim
    libqmi
    modemmanager
    lpac          # eSIM Local Profile Assistant

    # Estonian ID / digital signature
    qdigidoc
    web-eid-app
    opensc          # PKCS#11 driver + opensc-tool / pkcs11-tool
    pcsc-tools      # pcsc_scan for debugging the reader

    # CLI utilities
    tmux
    tldr
    yq-go           # YAML processor
    whois
    rclone          # rsync for cloud storage (Google Drive, S3, etc.)

    # Privacy / Anonymity
    tor-browser
    ivpn
    ivpn-service
    ivpn-ui
    xray

    # GNOME extensions
    gnomeExtensions.tlp-profile-switcher
  ];

  # PC/SC daemon — middleware for the smart card reader (Estonian ID)
  services.pcscd.enable = true;

  # The built-in reader (2ce3:9563 "Generic EMV Smartcard Reader") is not in
  # the shipped CCID udev rules, so pcscd hit LIBUSB_ERROR_ACCESS. Grant access.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="2ce3", ATTR{idProduct}=="9563", ENV{ID_SMARTCARD_READER}="1", TAG+="uaccess", MODE="0660", GROUP="pcscd"
  '';
}

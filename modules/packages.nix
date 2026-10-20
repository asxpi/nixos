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
    # sqlcipher (since v0.5.120) and curl: missing from upstream flake's buildInputs
    (inputs.anotherim.packages.${pkgs.system}.default.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [ pkgs.sqlcipher pkgs.curl ];
    }))

    # Gaming
    heroic

    # Development
    nodejs_22
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
    linode-cli      # Linode (Akamai) CLI
    packer          # image builder
    talosctl        # Talos OS CLI
    eksctl          # AWS EKS CLI
    # terragrunt    # broken in nixpkgs
    gh
    aider-chat      # AI pair programming CLI (OpenRouter via ~/.local/bin/aider)

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
    android-tools   # adb reverse for the phone-as-NFC-reader (vpcd) link

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
    gnomeExtensions.appindicator  # tray icons (StatusNotifierItem): another.im's "Stay connected when closed"
  ];

  # The AppIndicator extension's tray needs gnome-settings-daemon's udev rules
  # (NixOS wiki, GNOME: "Systray Icons").
  services.udev.packages = [ pkgs.gnome-settings-daemon ];

  # UnifiedPush distributor, so a server can wake push-capable apps
  # (another.im) after they have quit. KUnifiedPush defaults to KDE's ntfy
  # server; System Settings' "Push Notifications" page (kcm_push_notifications)
  # picks another. Its own unit is in share/systemd/user, which systemd.packages
  # does not read, so it is written out here (the package's, as of 26.04).
  systemd.user.services.kunifiedpush-distributor = {
    description = "KUnifiedPush Distributor";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.kdePackages.kunifiedpush}/bin/kunifiedpush-distributor";
      Type = "exec";
      BusName = "org.unifiedpush.Distributor.kde";
      TimeoutStopSec = "5sec";
      Slice = "background.slice";
      Restart = "on-failure";
    };
  };

  # PC/SC daemon — middleware for the smart card reader (Estonian ID)
  services.pcscd.enable = true;

  # vsmartcard vpcd: Android phone NFC as a PC/SC reader ("Virtual PCD") via the
  # Remote Smart Card Reader app; over USB: adb reverse tcp:35963 tcp:35963
  services.pcscd.readerConfigs = [ ''
    FRIENDLYNAME "Virtual PCD"
    DEVICENAME   /dev/null:0x8C7B
    LIBPATH      ${pkgs.vsmartcard-vpcd}/var/lib/pcsc/drivers/serial/libifdvpcd.so
    CHANNELID    0x8C7B
  '' ];

  # The built-in reader (2ce3:9563 "Generic EMV Smartcard Reader") is not in
  # the shipped CCID udev rules, so pcscd hit LIBUSB_ERROR_ACCESS. Grant access.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="2ce3", ATTR{idProduct}=="9563", ENV{ID_SMARTCARD_READER}="1", TAG+="uaccess", MODE="0660", GROUP="pcscd"
  '';
}

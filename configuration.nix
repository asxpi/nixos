# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  # boot.loader.systemd-boot.enable = true; #Disabled for GRUB
  boot.loader.efi.canTouchEfiVariables = true;

  # Grub
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  # boot.loader.grub.useOSProber = true;
  # boot.loader.grub.extraConfig = "GRUB_DISABLE_OS_PROBER=false";
  boot.loader.grub.extraEntries = ''
    menuentry "Arch Linux (zen)" {
      search --set=root --fs-uuid 15ae8384-3dfc-4915-9201-66ecfc5f230d
      linux /@/boot/vmlinuz-linux-zen root=UUID=15ae8384-3dfc-4915-9201-66ecfc5f230d rootflags=subvol=@ rw
      initrd /@/boot/initramfs-linux-zen.img
    }

    menuentry "Arch Linux (default)" {
      search --set=root --fs-uuid 15ae8384-3dfc-4915-9201-66ecfc5f230d
      linux /@/boot/vmlinuz-linux root=UUID=15ae8384-3dfc-4915-9201-66ecfc5f230d rootflags=subvol=@ rw
      initrd /@/boot/initramfs-linux.img
    }

    menuentry "Arch Linux (lts)" {
      search --set=root --fs-uuid 15ae8384-3dfc-4915-9201-66ecfc5f230d
      linux /@/boot/vmlinuz-linux-lts root=UUID=15ae8384-3dfc-4915-9201-66ecfc5f230d rootflags=subvol=@ rw
      initrd /@/boot/initramfs-linux-lts.img
    }
  '';

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Tallinn";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.asxpi = {
    isNormalUser = true;
    description = "Sergei P";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # Internet
      thunderbird
      telegram-desktop
      firefox-devedition-bin
      # claude-code is now provided by the flake
      zed-editor
    ];
  };

  # Install firefox.
  # programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    os-prober
    nano
    git
    btrfs-progs
    curl
    wget
    htop
    fastfetch
    nodejs_20
  ];

  # Create a wrapper script for nixos-rebuild
  environment.shellAliases = {
    nrs = "sudo nixos-rebuild switch && cd /etc/nixos && sudo git add -A && sudo git commit -m 'Update: $(date +%Y-%m-%d_%H:%M)' && sudo git push origin main";
  };

  environment.etc."gitconfig".text = ''
    [user]
      name = Sergei Poljanski
      email = me@asxp.io
    [init]
      defaultBranch = main
    [safe]
      directory = /etc/nixos
  '';

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}

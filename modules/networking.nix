# Networking and WWAN modem configuration
{ config, pkgs, lib, ... }:

{
  networking.hostName = "meow";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Fibocom EM120R-GL WWAN Modem Support
  # FCC unlock for Quectel EM120R-GL
  networking.modemmanager.fccUnlockScripts = [
    {
      id = "1eac:1001";
      path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/1eac:1001";
    }
  ];

  # udev rules for WWAN devices
  services.udev.extraRules = ''
    KERNEL=="wwan*mbim*", MODE="0660", GROUP="dialout"
    KERNEL=="wwan*qcdm*", MODE="0660", GROUP="dialout"
    KERNEL=="wwan*at*", MODE="0660", GROUP="dialout"
    KERNEL=="cdc-wdm*", MODE="0660", GROUP="dialout"
  '';

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
}

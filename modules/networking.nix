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

  # Quectel EM160R-GL WWAN Modem Support
  # FCC unlock for Quectel EM160R-GL (USB ID 1eac:100d)
  # Reuses the EM120R-GL (1eac:1001) script — same AT command across the family.
  networking.modemmanager.fccUnlockScripts = [
    {
      id = "1eac:100d";
      path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/1eac:1001";
    }
  ];

  # Kernel modules for WWAN/MBIM modems
  boot.kernelModules = [ "cdc_mbim" "qmi_wwan" "cdc_wdm" "mhi" ];

  # MediaTek MT7925 Wi-Fi: disable PCIe ASPM.
  # Why: under high throughput (>~50 Mbit/s sustained) the PCIe link enters L1
  # power-saving mid-flow and the firmware queue stalls, causing TX to decay
  # to zero and the driver to deauth (reason=3, locally_generated=1).
  # Verified live by reloading mt7925e with disable_aspm=1.
  boot.extraModprobeConfig = ''
    options mt7925e disable_aspm=1
    options cfg80211 ieee80211_regdom=EE
  '';

  # Ship the wireless regulatory database so cfg80211 can apply EE rules
  # (enables 6 GHz band 4 and active scanning on upper 5 GHz channels).
  hardware.wirelessRegulatoryDatabase = true;

  # udev rules for WWAN devices
  services.udev.extraRules = ''
    KERNEL=="wwan*mbim*", MODE="0660", GROUP="networkmanager"
    KERNEL=="wwan*qcdm*", MODE="0660", GROUP="networkmanager"
    KERNEL=="wwan*at*", MODE="0660", GROUP="networkmanager"
    KERNEL=="cdc-wdm*", MODE="0660", GROUP="networkmanager"
    KERNEL=="wwan*", MODE="0660", GROUP="networkmanager"
  '';

  # Ensure ModemManager starts before NetworkManager
  systemd.services.ModemManager = {
    wantedBy = [ "multi-user.target" ];
    before = [ "NetworkManager.service" ];
  };

  # WWAN modem connection is managed by NetworkManager / the GNOME applet.
  # A previous wwan-autoconnect oneshot service called `mmcli --simple-connect`
  # with a hardcoded APN and set up routing by hand. It fought NM for the modem
  # (endless "connecting") and its hardcoded APN broke when the SIM changed.
  # Removed: connect via the GNOME network applet using the carrier's GSM
  # profile instead. Re-add a service only if headless autoconnect is needed,
  # and if so set the NM profile's autoconnect=no to avoid contention.

  # IVPN service — installed but not auto-started at boot.
  # Start manually: `sudo systemctl start ivpn-service`
  services.ivpn.enable = true;
  systemd.services.ivpn-service.wantedBy = lib.mkForce [ ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Enable the firewall.
  networking.firewall.enable = true;
}

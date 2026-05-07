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
  '';

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

  # Auto-connect WWAN modem on boot (workaround for NM/MBIM-PCIe issue)
  systemd.services.wwan-autoconnect = {
    description = "Auto-connect WWAN modem";
    after = [ "ModemManager.service" ];
    wants = [ "ModemManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = pkgs.writeShellScript "wwan-connect" ''
        # Wait for modem to be available and get modem index
        MODEM=""
        for i in $(${pkgs.coreutils}/bin/seq 1 30); do
          MODEM=$(${pkgs.modemmanager}/bin/mmcli -L 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oE 'Modem/[0-9]+' | ${pkgs.coreutils}/bin/head -1 | ${pkgs.coreutils}/bin/cut -d/ -f2)
          [ -n "$MODEM" ] && break
          ${pkgs.coreutils}/bin/sleep 1
        done

        if [ -z "$MODEM" ]; then
          echo "No modem found"
          exit 1
        fi

        # Enable modem
        ${pkgs.modemmanager}/bin/mmcli -m $MODEM -e || true
        ${pkgs.coreutils}/bin/sleep 2

        # Connect with APN
        ${pkgs.modemmanager}/bin/mmcli -m $MODEM --simple-connect="apn=internet" || exit 0
        ${pkgs.coreutils}/bin/sleep 2

        # Get bearer info and configure interface
        BEARER=$(${pkgs.modemmanager}/bin/mmcli -m $MODEM 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Bearer" | ${pkgs.gnugrep}/bin/grep -oE '/[0-9]+' | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.coreutils}/bin/tr -d '/')
        if [ -n "$BEARER" ]; then
          IP=$(${pkgs.modemmanager}/bin/mmcli -b $BEARER 2>/dev/null | ${pkgs.gnugrep}/bin/grep "address:" | ${pkgs.gawk}/bin/awk '{print $NF}')
          GW=$(${pkgs.modemmanager}/bin/mmcli -b $BEARER 2>/dev/null | ${pkgs.gnugrep}/bin/grep "gateway:" | ${pkgs.gawk}/bin/awk '{print $NF}')
          PREFIX=$(${pkgs.modemmanager}/bin/mmcli -b $BEARER 2>/dev/null | ${pkgs.gnugrep}/bin/grep "prefix:" | ${pkgs.gawk}/bin/awk '{print $NF}')
          [ -z "$PREFIX" ] && PREFIX=30
          if [ -n "$IP" ] && [ -n "$GW" ]; then
            ${pkgs.iproute2}/bin/ip link set wwan0 up
            ${pkgs.iproute2}/bin/ip addr add $IP/$PREFIX dev wwan0 2>/dev/null || true
            # Add source-based routing for wwan0
            ${pkgs.iproute2}/bin/ip route add default via $GW dev wwan0 table 100 2>/dev/null || true
            ${pkgs.iproute2}/bin/ip rule add from $IP table 100 priority 100 2>/dev/null || true
            # Also add regular default route with low priority
            ${pkgs.iproute2}/bin/ip route add default via $GW dev wwan0 metric 700 2>/dev/null || true
          fi
        fi
      '';
      ExecStop = pkgs.writeShellScript "wwan-disconnect" ''
        MODEM=$(${pkgs.modemmanager}/bin/mmcli -L 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oE 'Modem/[0-9]+' | ${pkgs.coreutils}/bin/head -1 | ${pkgs.coreutils}/bin/cut -d/ -f2)
        [ -n "$MODEM" ] && ${pkgs.modemmanager}/bin/mmcli -m $MODEM --simple-disconnect 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link set wwan0 down 2>/dev/null || true
      '';
    };
  };

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

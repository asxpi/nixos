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
  boot.kernelModules = [ "cdc_mbim" "qmi_wwan" "cdc_wdm" "mhi" "sch_cake" "ifb" ];

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

    # EM160R-GL: no wakeup, no runtime PM.
    # Why: with the lid closed on AC, the connected modem woke s2idle within
    # ~1s every cycle (~1550 suspend/resume loops, 2026-09-21..22). Each resume
    # re-probed MHI until the firmware hung (MMIO reads 0xffffffff, stuck in
    # D3cold) and only a cold power-off recovered it.
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1eac", ATTR{device}=="0x100d", ATTR{power/wakeup}="disabled", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="mhi", KERNEL=="mhi[0-9]*", ATTR{power/wakeup}="disabled"
  '';

  # EM160R-GL cold-boot recovery.
  # Why: after a cold boot the modem often drops off the PCIe link ~10-20s
  # after probe ("Unable to change power state from D3cold to D0", config
  # space reads all-ones) and never brings up its wwan ports; only a platform
  # power cycle (hibernate/resume) recovered it. An ACPI _RST via the PCI
  # reset attribute does the same live. The first rescan catches the firmware
  # mid-boot with the generic Qualcomm ID 17cb:0304, which has no FCC unlock
  # script (ModemManager then fails with "Couldn't set operating mode"), so
  # once the firmware is up, re-enumerate again to get 1eac:100d back.
  # Verified live 2026-10-20 on kernel 7.2.11.
  systemd.services.wwan-coldboot-recover = {
    description = "Recover EM160R-GL WWAN modem dead after cold boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-trigger.service" ];
    serviceConfig.Type = "exec";
    script = ''
      dev=
      for d in /sys/bus/pci/devices/*; do
        [ "$(cat $d/vendor)" = 0x1eac ] && [ "$(cat $d/device)" = 0x100d ] && dev=$d
      done
      [ -n "$dev" ] || { echo "modem not found"; exit 0; }
      addr=$(basename $dev)

      wait_ports() {
        for _ in $(seq "$1"); do [ -e /sys/class/wwan/wwan0 ] && return 0; sleep 1; done
        return 1
      }
      rescan() {
        echo 1 > /sys/bus/pci/devices/$addr/remove
        echo 1 > /sys/bus/pci/rescan
      }

      wait_ports 60 && { echo "modem up, nothing to do"; exit 0; }

      echo "no wwan ports after 60s, resetting $addr via ACPI _RST"
      [ -e $dev/driver ] && echo $addr > $dev/driver/unbind
      echo acpi > $dev/reset_method
      echo 1 > $dev/reset
      rescan
      wait_ports 90 || { echo "modem still down after reset"; exit 1; }
      sleep 30
      rescan
      wait_ports 60 || { echo "modem lost after re-enumeration"; exit 1; }
      echo "modem recovered as $(cat /sys/bus/pci/devices/$addr/vendor):$(cat /sys/bus/pci/devices/$addr/device)"
    '';
  };

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

  # WWAN bufferbloat mitigation (cake shaping on the modem link).
  # Why: operator LTE schedulers buffer deeply; loaded latency measured
  # 305/449 ms (down/up) at ~51/5 Mbit/s in Gyumri (Viva-MTS, B20+B3+B7 3CA).
  # Shaping slightly below measured throughput moves the queue onto this host
  # where cake keeps it short — loaded latency dropped to ~70 ms. Applied by a
  # NM dispatcher hook so it survives modem reconnects / interface recreation.
  # Tune the two rates when the serving cell changes (mmcli / AT+QCAINFO).
  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeShellScript "wwan-cake" ''
      IF="$1"; ACTION="$2"
      [[ "$IF" == wwan* ]] || exit 0
      TC=${pkgs.iproute2}/bin/tc; IP=${pkgs.iproute2}/bin/ip
      IFB="ifb-$IF"; UP=4500kbit; DOWN=45mbit
      case "$ACTION" in
        up)
          $IP link add "$IFB" type ifb 2>/dev/null || true
          $IP link set "$IFB" up
          $TC qdisc replace dev "$IF" root cake bandwidth $UP besteffort nat ack-filter
          $TC qdisc replace dev "$IF" handle ffff: ingress
          $TC filter replace dev "$IF" parent ffff: matchall             action mirred egress redirect dev "$IFB"
          $TC qdisc replace dev "$IFB" root cake bandwidth $DOWN besteffort ingress
          ;;
        down)
          $IP link del "$IFB" 2>/dev/null || true
          ;;
      esac
    '';
  }];

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

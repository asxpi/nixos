# Power management — ThinkPad T14 Gen 2 (AMD)
{ config, pkgs, lib, ... }:

{
  # AMD P-State driver (active mode for full EPP control)
  boot.kernelParams = [ "amd_pstate=active" ];

  # CPU frequency scaling
  powerManagement.cpuFreqGovernor = "powersave";

  # Disable power-profiles-daemon (conflicts with TLP)
  services.power-profiles-daemon.enable = false;

  # TLP — main power management daemon
  services.tlp = {
    enable = true;
    settings = {
      # CPU
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "balanced";

      # AMD P-State
      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";

      # WiFi
      WIFI_PWR_MGT_ON_AC = "off";
      WIFI_PWR_MGT_ON_BAT = "on";

      # PCIe ASPM
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "default";

      # Runtime PM
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # NVMe
      NVME_RUNTIME_PM_ON_AC = "on";
      NVME_RUNTIME_PM_ON_BAT = "auto";

      # USB autosuspend
      USB_AUTOSUSPEND = 1;
    };
  };

  # Bluetooth off at boot
  hardware.bluetooth.powerOnBoot = true;

  # Battery monitoring
  services.upower.enable = true;

  # powertop for diagnostics
  environment.systemPackages = [ pkgs.powertop ];
}

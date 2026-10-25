# nebula hardware: ZFS filesystems, boot, kernel modules
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.supportedFilesystems = [ "zfs" ];

  boot.initrd.availableKernelModules = [
    "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"
  ];
  boot.initrd.kernelModules = [ "zfs" ];
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # ip6_tables: richiesti da k3s/Flannel anche con IPv6 disabilitato
  boot.kernelModules = [
    "ip6_tables"
    "ip6table_mangle"
    "ip6table_raw"
    "ip6table_filter"
  ];

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # ASPM non forzato: ACPI FADT dichiara ASPM non supportato; pcie_aspm=force è rischioso.
  # EPP "power": riduce il package power idle (A/B misurato ~1,50 -> ~1,43 W).
  systemd.services.cpu-epp = {
    description = "Set CPU energy performance preference to power";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        echo power > "$f"
      done
    '';
  };

  # ponytail: rigenerare al primo install (head -c4 /dev/urandom | od -A none -t x4)
  networking.hostId = "963e586d";
}

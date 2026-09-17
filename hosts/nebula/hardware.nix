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

  # ponytail: rigenerare al primo install (head -c4 /dev/urandom | od -A none -t x4)
  networking.hostId = "963e586d";
}

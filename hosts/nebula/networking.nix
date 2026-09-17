# nebula static IP, firewall, DNS
{ config, lib, pkgs, ... }:

{
  networking.hostName = "nebula";

  networking.useDHCP = false;
  networking.interfaces.enp1s0.ipv4.addresses = [
    {
      address = "10.0.40.2";
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = "10.0.40.1";
  networking.nameservers = [
    "127.0.0.1"  # Technitium locale
    "1.1.1.1"
    "9.9.9.9"
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      53
      80
      443
      6443
    ];
    allowedUDPPorts = [ 53 ];
  };

  networking.enableIPv6 = false;
}

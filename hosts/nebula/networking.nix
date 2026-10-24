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
    "10.0.40.2"  # Technitium (LAN); k3s scarta il loopback 127.0.0.1 per i pod
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      53
      80
      443
      6443
      445   # SMB (samba, share /mnt/media)
      6881  # peer BitTorrent (qBittorrent, hostPort)
    ];
    allowedUDPPorts = [
      53
      6881 # peer BitTorrent/uTP (qBittorrent, hostPort)
    ];
  };

  networking.enableIPv6 = false;
}

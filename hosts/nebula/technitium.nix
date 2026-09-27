# Technitium DNS server
{ config, lib, pkgs, unstable, ... }:

{
  services.technitium-dns-server = {
    enable = true;
    package = unstable.technitium-dns-server;  # nixpkgs-unstable (15.x), vedi flake.nix
    # openFirewall=false: gestiamo le porte manualmente sotto per controllare
    # che 5380 (web UI) sia accessibile solo in loopback (via Traefik), non dalla LAN.
    openFirewall = false;
  };

  networking.firewall = {
    allowedUDPPorts = [ 53 ];
    allowedTCPPorts = [ 53 ];
    # 5380 (web UI): raggiungibile solo da loopback (tunnel SSH) e dai pod k3s
    # (Traefik, via Endpoints): kube-router accetta il traffico pod→host nella
    # catena KUBE-ROUTER-INPUT prima di nixos-fw; i client LAN vengono droppati
    # da nixos-fw (5380 non è tra le porte aperte).
    extraInputRules = ''
      -A INPUT -i lo -p tcp --dport 5380 -j ACCEPT
    '';
  };
}

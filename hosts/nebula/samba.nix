# Samba: condivide /mnt/media (dataset tank/media) in LAN verso Windows Explorer
# Accesso solo per l'utente `cosimo`; password da settare una volta sul server:
#   sudo smbpasswd -a cosimo
# (DB password Samba separato dalla password di sistema, persistito in /var/lib/samba)
{ ... }:

{
  services.samba = {
    enable = true;
    # Le porte sono dichiarate solo in networking.nix (unica fonte di verita')
    openFirewall = false;
    settings = {
      global = {
        "server role" = "standalone server";
        # SMB2 minimo: via il vecchio SMB1
        "server min protocol" = "SMB2";
        "map to guest" = "never";
        # Binda solo LAN + lo, non le interfacce k3s (cni0, flannel.1, ...)
        interfaces = "lo enp1s0";
        "bind interfaces only" = "yes";
      };
      media = {
        path = "/mnt/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "cosimo";
      };
    };
  };

  # La radice del dataset deve essere scrivibile da cosimo (i file dentro
  # mantengono i permessi gia' presenti)
  systemd.tmpfiles.rules = [
    "d /mnt/media 0775 cosimo users - -"
  ];
}

# Samba: condivide /mnt/media (dataset tank/media) in LAN verso Windows Explorer
# Accesso solo per l'utente `cosimo`; password da settare una volta sul server:
#   sudo smbpasswd -a cosimo
{ ... }:

{
  services.samba = {
    enable = true;
    openFirewall = false;
    # Solo smbd: nmbd (browsing NetBIOS) e winbindd (domain join) non servono
    nmbd.enable = false;
    winbindd.enable = false;
    settings = {
      global = {
        "server role" = "standalone server";
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

  # La radice e le sottodirectory note del dataset sono di cosimo: la regola d
  # crea la dir se manca e corregge owner/group/permessi se esiste gia'.
  systemd.tmpfiles.rules = [
    "d /mnt/media 0775 cosimo users - -"
    "d /mnt/media/movies 0775 cosimo users - -"
    "d /mnt/media/series 0775 cosimo users - -"
  ];
}

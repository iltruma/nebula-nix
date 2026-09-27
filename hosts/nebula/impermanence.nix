# impermanence: bind-mount su /persist dei path da preservare tra reboot
{ ... }:

{
  environment.persistence."/persist" = {
    hideMounts = true;

    files = [
      "/etc/machine-id"
    ];

    directories = [
      "/var/lib/nixos"  # UID/GID allocati da NixOS
      "/var/log"
      "/var/lib/samba"  # tdb Samba: passdb (smbpasswd), lock, share info
      # /persist/sops/ usato direttamente da sops-nix (keyFile)
    ];
  };
}

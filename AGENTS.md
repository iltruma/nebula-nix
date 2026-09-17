# Istruzioni agenti — nebula-nix

Repo minimale NixOS per il server `nebula` (Dell Optiplex 3050, k3s + Flux).

## Cosa c'è qui

Solo nebula: flake + `hosts/nebula/` + `modules/` + `secrets/` (SOPS) + `k8s/`
(manifesti Flux).

## Regole operative

- **Rebuild**: eseguito dall'utente Cosimo su nebula via SSH
  (`sudo nixos-rebuild switch --flake ~/nebula-nix#nebula`; il repo viene
  sincronizzato su nebula con rsync prima). L'agente NON lancia mai nixos-rebuild.
- **Zona rossa** (mostrare e aspettare conferma): nixos-rebuild switch/boot,
  kubectl apply/delete, sops encrypt/decrypt, chiamate HTTP reali
- **Zona verde**: leggere file, scrivere/modificare codice Nix/k8s/docs,
  `nix flake check`
- **Secrets**: mai plaintext; SOPS + age; non decifrare `*.enc.yaml`
- **Commit**: `<tipo>(<scope>): <descrizione>` — italiano, scope nix/k8s/docs.
  L'agente può committare dopo aver proposto (messaggio + stat). Mai push.
- Prima di modifiche non banali: spiegare cosa/come/impatto e aspettare conferma

## Verifiche

- `nix flake check` deve passare
- k3s: `sudo k3s kubectl get nodes` (via SSH su nebula)
- Flux: `sudo k3s kubectl -n flux-system get kustomizations`

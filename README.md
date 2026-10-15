# nebula-nix

Flake NixOS minimale per **nebula** (Dell Optiplex 3050): k3s + Technitium DNS +
Flux GitOps. Cartella di lavoro per la config di rete VLAN (hEX S MikroTik).

## Struttura

```
flake.nix            entry point (nixpkgs 25.11 + unstable per Technitium)
hosts/nebula/        tutta la config del server
  networking.nix     IP statico 10.0.40.2 (VLAN 40 dell'hEX S), firewall
  k3s.nix            k3s server + bootstrap manifests Flux + CoreDNS custom
  technitium.nix     DNS (split-horizon, blocklist)
  disko.nix          partizionamento ZFS dichiarativo (tank)
  hardware.nix       kernel, initrd, boot, hostId
  impermanence.nix   persistenza /persist
  beszel-agent.nix   monitoring host
  backup.nix         rclone → R2 (in pausa, non importato)
  dns/               zona BIND lab.paroparo.it + blocklist (import manuale)
modules/             helper cross-host: common (utenti, SSH, sops), keys
secrets/             secret host cifrati SOPS + age (*.enc.yaml)
k8s/                 manifesti GitOps, sincronizzati da Flux (kustomization nebula)
```

## Aggiornamenti automatici

Nessun merge automatico: ogni aggiornamento arriva come PR e la mergi tu.
Su ogni PR gira `ci.yml`. Il merge di una PR su `k8s/` è un deploy (Flux
riconcilia in ~10 min); il merge di una PR su `flake.lock` **non** applica
nulla, il rebuild resta manuale.

| Superficie | Strumento | Config |
|---|---|---|
| `flake.lock` (nixpkgs, unstable, sops-nix, disko, impermanence) | Dependabot | `.github/dependabot.yml` |
| chart Helm traefik/cert-manager (`k8s/infra/*/install/helmrelease.yaml`) | Renovate | `renovate.json` |
| immagini in `k8s/apps/*/deployment.yaml` | Renovate | `renovate.json` |
| azioni CI e `KUBECONFORM_VERSION` (`.github/workflows/ci.yml`) | Renovate | `renovate.json` |
| chart flux2 in `hosts/nebula/k3s.nix` | Renovate | `renovate.json` |

Dependabot funziona da solo, appena il file è su `main`. Renovate invece va
installato una volta come app hosted sul repo (`https://github.com/apps/renovate`,
*only select repositories* → `iltruma/nebula-nix`): senza l'app il file
`renovate.json` non produce nulla.

Restano manuali: il cambio canale in `flake.nix` (es. `nixos-26.05` →
`nixos-27.05`), che nessuno dei due propone, e il rebuild su nebula.

## Comandi

```bash
# verifica
nix flake check

# rebuild (SU nebula, da sessione SSH):
sudo nixos-rebuild switch --flake ~/nebula-nix#nebula
```

## Regole operative

- Il rebuild di nebula va eseguito in sessione SSH sul server, non da remoto
  via `--target-host`
- Secret: mai plaintext in repo — `sops` (`.sops.yaml`, chiave age in
  `/persist/sops/age/keys.txt` su nebula)
- Commit: `<tipo>(<scope>): <descrizione>` in italiano (nix/k8s/ci/docs)
- Il cluster k8s sincronizza da `k8s/` (Flux, ~10 min); il deploy key GitHub
  è in `secrets/flux-git-auth.enc.yaml`

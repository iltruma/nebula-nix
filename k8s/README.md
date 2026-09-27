# k8s — GitOps con Flux CD v2

Questa cartella contiene tutto ciò che gira sul cluster k3s (`nebula`, singolo
nodo su 10.0.40.2), gestito in **GitOps** da Flux CD v2: lo stato desiderato
vive qui in Git, il kustomize-controller lo sincronizza nel cluster ogni 10
minuti.

## Struttura

```
k8s/
├── clusters/
│   └── nebula/                        ← Kustomization radice per il cluster "nebula"
│       ├── traefik.yaml               Kustomization install → k8s/infra/traefik/install
│       ├── traefik-config.yaml        Kustomization config  → k8s/infra/traefik/config
│       ├── cert-manager.yaml          Kustomization install → k8s/infra/cert-manager/install
│       ├── infrastructure.yaml        Kustomization config  → k8s/infra/cert-manager/config
│       └── apps.yaml                  Kustomization → k8s/apps/
│
├── infra/                             ← Infrastruttura (HelmRelease, ClusterIssuer, …)
│   ├── traefik/                       HelmRelease Traefik 3.7.x + TLSStore
│   └── cert-manager/                  HelmRelease cert-manager + ClusterIssuer + secret.enc.yaml
│
└── apps/                              ← Servizi applicativi, una cartella per servizio
    ├── uptime-kuma/                   Status page
    ├── beszel/                        Hub + agent monitoring
    ├── homepage/                      Dashboard dichiarativa
    ├── technitium/                    Ingress verso Technitium su host (namespace infra-proxy)
    ├── infra-proxy/                   Namespace per i proxy Traefik verso host
    ├── jellyfin/                      Jellyfin Media Server
    └── <nome>/                        Qualsiasi nuovo servizio
```

## Come funziona

`hosts/nebula/k3s.nix` installa Flux (via HelmChart `flux2`) e crea la
Kustomization radice `nebula`, che punta a `k8s/clusters/nebula`. I file
`traefik.yaml`, `cert-manager.yaml`, `traefik-config.yaml`, `infrastructure.yaml`
e `apps.yaml` sono oggetti `Kustomization` Flux: i layer infra si riconciliano
in sequenza (traefik + cert-manager → config → apps, via `dependsOn`, per
garantire che CRD e cert siano pronti).

## Il nome della Kustomization radice è identità del GC

Con `prune = true` (vedi `flux-cluster-kustomization` in `k3s.nix`), il nome
della Kustomization radice non è un dettaglio estetico: identifica le risorse
gestite. Rinominarla fa sì che, al prossimo switch, la vecchia venga rimossa
dal cluster e il suo **finalizer** triggeri il GC di **tutto** l'albero gestito
— Deployment *e* PVC con i dati. Succeso il 27/09 col rename `dyson` → `nebula`:
wizard jellyfin e dati di uptime-kuma cancellati.

Per rinominarla senza perdite, rimuovi prima il finalizer dalla vecchia:

```bash
kubectl -n flux-system patch kustomization <vecchio-nome> --type=merge \
  -p '{"metadata":{"finalizers":null}}'
```

La Kustomization muore senza GC; la nuova adotta le risorse esistenti (stessi
manifest, stessi nomi) e le PVC restano intatte.

Aggiungere un nuovo servizio:

1. Crea `k8s/apps/<nome>/` con i suoi manifest + `kustomization.yaml`.
2. Commit e push.
3. Al prossimo polling (~10 min) Flux applica la cartella. Per forzare subito:
   ```bash
   flux reconcile kustomization apps --with-source
   ```

## SOPS — decifrazione automatica dei secret

I file `*.enc.yaml` sono secret Kubernetes cifrati con **SOPS + age**. Il
kustomize-controller li decifra autonomamente usando la chiave privata age
contenuta nel Secret `sops-age` nel namespace `flux-system`.

La chiave pubblica age usata per la cifratura è in `.sops.yaml` alla radice
del repo. Per cifrare un nuovo secret:

```bash
# Cifra un Secret Kubernetes esistente
sops --encrypt k8s/apps/<nome>/secret.yaml > k8s/apps/<nome>/secret.enc.yaml
rm k8s/apps/<nome>/secret.yaml   # mai committare il plaintext
```

Verifica che il file contenga `sops:` metadata (e non `data:` in chiaro) prima
di committare.

## Bootstrap (prima installazione, da rifare solo in disaster recovery)

Non serve `flux bootstrap`: Flux è installato e configurato interamente da
NixOS in `hosts/nebula/k3s.nix`:

- `HelmChart flux2` (namespace kube-system) installa Flux nel cluster
- i manifest `flux-git-repository` (GitRepository `flux-system` → GitHub) e
  `flux-cluster-kustomization` (root Kustomization → `k8s/clusters/nebula`)
  vengono applicati automaticamente da k3s da
  `/var/lib/rancher/k3s/server/manifests/`
- i Secret `flux-git-auth` (deploy key SSH) e `flux-sops-age` (decifrazione) sono
  distribuiti via **sops-nix**: sops li piazza in `/run/secrets/k3s/` e
  tmpfiles.li li symlinka nei manifest di k3s prima che parta (vedi
  `k3s.nix` voes `systemd.tmpfiles.rules`)

Quindi in disaster recovery basta reinstallare nebula con il flake
(`sudo nixos-rebuild switch --flake ~/nebula-nix#nebula`) e il cluster si
ricostruisce da solo, secret inclusi.

## Verifica

```bash
flux get kustomizations          # tutte Ready
flux get helmreleases -A         # Traefik, cert-manager Ready
kubectl get pods -A              # nessun pod in CrashLoopBackOff

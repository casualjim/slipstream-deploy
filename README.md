# Slipstream Deploy

Slipstream-deploy provisions the minimal cloud resources required to run a Kubernetes
cluster and provides a complete, kustomize‑based platform layer of manifests to
configure the cluster (ingress, cert-manager, NATS, Restate operator, etc.).

High-level summary
- OpenTofu (`tofu/infra`) provisions cloud resources only: VPC, Vultr managed
  Kubernetes cluster, basic firewall rules. It reads SOPS‑encrypted secrets for
  bootstrap where needed.
- Cluster add-ons and application manifests are entirely managed with kustomize
  (k8s/). These are rendered and applied with the repository's mise tasks.

Quick links
- tofu infra: tofu/infra
- kustomize manifests: k8s/
- deployment helpers (mise tasks): .mise/tasks/deploy/
- verification manifests: k8s/verification/
- sample app pattern: sample-app.yaml

Prerequisites
- mise CLI (repo uses mise tasks for build/deploy). Examples:
  - `mise deploy:build --environment dev --provider vultr`
  - `mise deploy:preview --environment dev --provider vultr`
  - `mise deploy:promote --environment dev --provider vultr`
- OpenTofu for `tofu/infra` (providers: Vultr, Cloudflare, etc.).
- `vultr` CLI and `kubectl` for kubeconfig and cluster ops.
- `sops` and access to AWS KMS key configured in `.sops.yaml` to decrypt `tofu/infra/secrets/*.yaml` and kustomize overlay secrets.

Quickstart (operator)
1. Bootstrap cloud infra (once per environment):

  cd tofu/infra
  tofu init -backend-config=backend.hcl
  tofu apply

   Notes:
   - `backend.hcl` is intentionally not committed; provide your backend settings
     (Backblaze B2 or S3‑compatible) per environment.
   - Tofu creates the VPC, managed Kubernetes cluster, and firewall. Sensitive
     outputs (e.g., kubeconfig, Cloudflare token, Step CA materials) are surfaced to
     operators as needed.

1. Fetch the kubeconfig for your cluster (example uses the vultr CLI):

  mise fetch-kubeconfig --cluster slipstream-dev-cluster

   This will write a kubeconfig to ~/.kube/config. The repo's .mise task
  (fetch-kubeconfig) uses `vultr kubernetes kubeconfig` and decodes the base64 kubeconfig.

2. Deploy the platform (kustomize -> server‑side apply):

  # render manifests
  mise deploy:build --environment dev

  # preview (server side dry-run)
  mise deploy:preview --environment dev

  # promote (apply to cluster)
  mise deploy:promote --environment dev

Important notes
- Secrets: OpenTofu and kustomize overlays consume SOPS‑encrypted files. Do not
  commit unencrypted secrets. See `docs/operations/secrets.md`.
- Platform manifests rely on cert-manager + a Step Cluster Issuer (Smallstep step‑issuer)
  and ingress‑nginx upstream client mTLS. See `k8s/verification/*` for canonical patterns.
- The mise tasks enable Helm and alpha plugins and wire an ephemeral `KUSTOMIZE_PLUGIN_HOME`
  so `ksops` can decrypt secrets during `kustomize build`.

Where to look next
- docs/architecture.md — high-level architecture and components
- docs/operational-runbook.md — deploy/rollback/promote procedures and verification checklist

Maintainers: after pulling these changes please run the verification checklist in
docs/operational-runbook.md to confirm environment-specific details (backend
configs, SOPS keys, and API tokens).

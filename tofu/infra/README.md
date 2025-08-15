# OpenTofu (infra)

## Purpose

This OpenTofu root (`tofu/infra`) provisions the minimal cloud resources
required to bootstrap a Kubernetes cluster on Vultr and exposes a small set
of sensitive outputs used by operators during cluster bootstrapping.

## What it creates

- Vultr VPC (`vultr_vpc`)
- Vultr managed Kubernetes cluster (`vultr_kubernetes`)
- Baseline firewall rules to allow SSH/HTTP/HTTPS (IPv4 and IPv6)
- Reads SOPS‑encrypted secrets from `tofu/infra/secrets` and exposes
	operator‑focused outputs

## Important constraints

- OpenTofu is only used to provision cloud resources required to make the
	Kubernetes cluster functional. The repository's platform layer (ingress,
	cert‑manager, NATS, Restate, etc.) is entirely managed with kustomize and is
	deployed via the mise tasks in `.mise/tasks/deploy/`. There is no second
	OpenTofu root that manages platform add‑ons.

## Secrets and SOPS

- Secrets for this root live in `tofu/infra/secrets/*.yaml` and are
	read by `data "sops_file"` in `providers.tf`. This requires SOPS and the
	appropriate decryption keys (AWS KMS or another key service depending on
	your `.sops.yaml`). See `.sops.yaml` and `docs/operations/secrets.md` for guidance.

## Outputs

The infra root exports several outputs intended for operator convenience. They
are not wired automatically into any platform IaC within this repository; the
platform stage is driven from the `k8s/` manifests.

Key outputs (sensitive where noted):

- `kubeconfig_raw` / `kubeconfig_decoded` (sensitive) — base64 / decoded
	kubeconfig for the Vultr cluster
- `cloudflare_api_token` (sensitive) — Cloudflare token for external‑dns / ACME
- `step_ca_url`, `step_root_ca_pem`, `step_provisioner_kid`,
	`step_provisioner_password` (sensitive) — Smallstep CA provisioning material
	consumed by cert‑manager Step ClusterIssuer
- `nats_*_creds_b64` (sensitive) — encoded NATS credentials used by manifests

## How to apply

1) Initialize with a backend config (e.g. `backend.hcl`). The project can use an
	 S3‑compatible backend; keep `backend.hcl` uncommitted.

```sh
cd tofu/infra
tofu init --backend-config=backend.hcl
tofu apply
```

Optional workspaces per environment:

```sh
tofu workspace new dev   # once
tofu workspace select dev
```

## Notes on backend and locking

- Provide a `backend.hcl` for remote state. For AWS S3 backends, prefer a
	DynamoDB table for locks or use an equivalent external locking mechanism in CI.

## Maintenance notes

- Pin provider and module versions as needed.
- The OpenTofu code reads SOPS files; avoid committing plaintext secrets.

## Files of interest

- `tofu/infra/main.tf`
- `tofu/infra/providers.tf`
- `tofu/infra/variables.tf`
- `tofu/infra/secrets/{base.yaml,dev.yaml}`
- `tofu/infra/modules/vultr/main.tf`

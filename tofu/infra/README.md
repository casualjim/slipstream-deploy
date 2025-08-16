# OpenTofu (infra)

## Purpose

This OpenTofu root (`tofu/infra`) provisions the minimal cloud resources
required to bootstrap a Kubernetes cluster on Vultr or OVH and exposes a small set
of sensitive outputs used by operators during cluster bootstrapping.

## What it creates

- On Vultr (cloud=vultr):
	- Vultr VPC (`vultr_vpc`)
	- Vultr managed Kubernetes cluster (`vultr_kubernetes`)
	- Baseline firewall rules to allow SSH/HTTP/HTTPS (IPv4 and IPv6)
- On OVH (cloud=ovh):
	- OVH managed Kubernetes cluster (`ovh_cloud_project_kube`)
	- Node pool (`ovh_cloud_project_kube_nodepool`)
- Reads SOPS‑encrypted secrets from `tofu/infra/secrets` and exposes operator‑focused outputs

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

## Configuration

Select the target cloud with the `cloud` variable (`vultr` by default). For OVH,
provide credentials via environment variables or SOPS secrets:

- Env vars: `OVH_APPLICATION_KEY`, `OVH_APPLICATION_SECRET`, `OVH_CONSUMER_KEY`
- Or SOPS keys in `secrets/base.yaml`: `ovh.applicationKey`, `ovh.applicationSecret`, `ovh.consumerKey`

Key OVH variables (set these for your environment; examples are placeholders):

- `ovh_project_id` (e.g., <YOUR_OVH_PROJECT_ID>)
- `ovh_region` (e.g., <REGION>)
- `ovh_k8s_version` (e.g., <K8S_VERSION>)
- `ovh_cluster_name` (e.g., <CLUSTER_NAME>)
- Node pool: `ovh_node_flavor` (e.g., <FLAVOR>), `ovh_nodepool_size` (e.g., <SIZE>), autoscale min/max (e.g., <MIN>/<MAX>)

Optional: `ovh_create_buckets` and `ovh_bucket_region` to plan for S3 buckets (creation may be managed externally).

## Outputs

The infra root exports several outputs intended for operator convenience. They
are not wired automatically into any platform IaC within this repository; the
platform stage is driven from the `k8s/` manifests.

Key outputs (sensitive where noted):

- `kubeconfig_decoded` (sensitive) — decoded kubeconfig for the selected cloud

## How to apply

1) Initialize with a backend config (e.g. `backend.hcl`). The project can use an
	 S3‑compatible backend; keep `backend.hcl` uncommitted.

If you lost your `backend.hcl`, copy `backend.hcl.example` and fill in placeholders:

```sh
cp backend.hcl.example backend.hcl
# edit backend.hcl to set bucket, endpoint, region, and leave credentials in env
```

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
- `tofu/infra/modules/ovh/main.tf`

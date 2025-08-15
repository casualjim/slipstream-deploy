# Restate Operator (Self-Hosted)

This stack installs the upstream Restate operator and declares a single `RestateCluster` that uses the built‑in replicated (Raft) metadata store – not an object storage backed metadata store. We intentionally disable `auto-provision` and perform a one‑time manual provisioning step with `restatectl` after the pods start.

## What the platform installs

- Helm release `restate-operator` (chart `oci://ghcr.io/restatedev/restate-operator-helm`, version pinned to `1.7.4`) in namespace `restate-operator`.
- A `RestateCluster` resource; the operator creates the workload namespace of the same name.

## Why Raft (Replicated) Metadata

Primary driver: Vultr Object Storage is missing / inconsistently implements several S3 behaviors the Restate object‑store metadata backend relies on (strongly consistent prefix listings, low‑latency propagation of writes, and reliable conditional semantics / atomic overwrite expectations). In practice we observed delayed visibility and non‑deterministic ordering for recently written keys during evaluation. Rather than build compensating logic or risk subtle metadata corruption / split‑brain scenarios, we selected the replicated (Raft) metadata store.

Secondary reasons: keep the initial footprint minimal and avoid external object storage dependency in the consensus path.

Benefits:

- Fast local metadata operations (no object store RTT in the hot path).
- Simpler failure model (pods + PVC only) for early development.
- Deterministic bootstrap via a manual `restatectl provision` ensuring we control when the cluster becomes writable.

Trade‑offs:
- Requires manual (or scripted) provisioning once per cluster lifecycle (before first use).
- No automatic snapshots to object storage yet (future enhancement).
- Higher steady‑state metadata write amplification across pods vs single remote object store.

Migration path (future): If/when we move to an object store with the requisite semantics (e.g. AWS S3 / MinIO with versioning & strong read‑after‑write for overwrites) we can flip `[metadata-server].type` to `object-store`, enable `auto-provision = true`, and introduce snapshot retention / off‑cluster restore flows.

## Current Cluster Config (Effective)

Excerpt of the effective config TOML:

```
roles = ["worker","admin","log-server","metadata-server","http-ingress"]
auto-provision = false
default-num-partitions = 128
default-replication = 2

[metadata-server]
type = "replicated"  # Raft

[metadata-client]
addresses = ["http://restate:5122/"]

[bifrost]
default-provider = "replicated"
```

Key points:
- `auto-provision = false` because the replicated (Raft) metadata store requires an explicit provisioning step. Enabling auto-provision here could race with pod readiness.
- Replication factor for user data defaults to 2 (tunable later).
- All core roles are co‑located on every pod for simplicity.

## Manual Provisioning Procedure

After the operator deploys and the `restate-*` pods are Running:

```
kubectl --namespace <clusterName> exec --stdin --tty restate-0 -- restatectl provision
```

Notes:
- Run it exactly once; it is idempotent but repeated calls after success are unnecessary.
- If you scale the cluster later, joining nodes do not require a new provision.
- Verify status with:
```
kubectl --namespace <clusterName> exec --stdin --tty restate-0 -- restatectl status
```

## Inputs

Under overlays/values:
- `clusterName` – cluster / namespace name (default `restate-dev`).
- `image` – Restate server image (default `restatedev/restate:1.4`).
- `replicas` – number of pods (default 3). Should be >=3 for Raft quorum (odd numbers recommended).

Object storage related keys (`restate:s3Hostname`, etc.) are currently accepted but not yet wired into the active config (planned for future snapshot/export integration). They can be omitted for now.

## (Deferred) Object Storage & Snapshots

Code computes placeholder S3 URIs for potential metadata & snapshot paths, but we do not pass them into the config while using the replicated store. When we transition to the object‑store metadata backend we will:
- Switch `[metadata-server] type = "object-store"` (or equivalent upstream setting).
- Set `auto-provision = true` (operator can then bootstrap automatically).
- Provide bucket, endpoint, and credentials via env or Secrets.

## Secrets Handling (Dev)

For now, no additional Kubernetes Secrets are created for Restate itself; credentials (if any are later added for object storage) will be sourced from SOPS‑encrypted manifests. Because the operator owns the workload namespace creation, embedding secrets directly would require waiting for namespace creation; we postpone that until object storage integration lands.

## Operational Considerations

- Pod Replacement: Raft state is persisted on the pod’s volume (requested 40Gi). Losing a majority simultaneously will require re‑provision or restore (add snapshotting before production use).
- Scaling: Keep replica count odd (3,5) to maximize availability without unnecessary quorum size.
- Backups: Not yet implemented; add periodic snapshot & off‑cluster copy before production.

## Commands

Use mise tasks for deploy operations:
- Render: `mise deploy:build --environment <env> --provider <provider>`
- Preview: `mise deploy:preview --environment <env> --provider <provider>`
- Apply: `mise deploy:promote --environment <env> --provider <provider>`

Post‑deploy (one time): run the provisioning command above.

## Next Steps / TODO

1. Add automated provisioning hook (optional) gated behind a feature flag.
2. Integrate snapshot uploads to object storage & document restore flow.
3. Introduce a dedicated Secret once namespace creation ordering is handled safely.
4. Add readiness / liveness probes tuning (if defaults insufficient).
5. Add metrics & tracing export (e.g., OTLP collector) once needed.

## Summary

We currently run a minimal self‑hosted Restate cluster using the replicated (Raft) metadata store with manual provisioning for controlled bootstrap. Documentation now reflects the absence of an object storage metadata backend and clarifies future integration points.


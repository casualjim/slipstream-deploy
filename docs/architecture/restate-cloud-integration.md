# Restate Cloud Integration

Current approach: use the upstream operator (Helm) plus a single `RestateCloudEnvironment` CRD. No custom tunnel Deployment, no operator auth secret transformation, no manual NetworkPolicy.

## What the platform installs

| Resource | Purpose |
|----------|---------|
| Helm release `restate-operator` (version pinned) | Installs CRDs & controller |
| Secret `restate-cloud-env` | Holds environment API token (`token`) used for tunnel auth (SOPS‑encrypted in overlays) |
| `RestateCloudEnvironment` CR | Declares environment (id, region, signing key) and desired tunnel spec |

The operator reconciles the CR and creates/manages the tunnel pod(s).

## Required inputs

- `environmentId`
- `signingPublicKey`
- `tunnelCreds` (secret) – environment API token (provided via SOPS‑encrypted Secret)
- `cloudRegion` (defaults to `us` if omitted)

## Optional inputs

- `remoteProxyEnabled` (boolean, default false) – enables proxy ports in the tunnel
- `tunnelImage` – override default tunnel image

## CR Spec Shape (simplified)

```
apiVersion: restate.dev/v1beta1
kind: RestateCloudEnvironment
spec:
	environmentId: <env>
	region: <region>
	signingPublicKey: <pubkey>
	authentication:
		secret:
			name: restate-cloud-env
			key: token
	tunnel:
		image: <image>
		replicas: 1
		remoteProxy: <bool>
		resources: {...}
```

## Service Deployment

Platform services using Restate define their own `RestateDeployment` objects (not auto-generated here). They reference the environment by name (we derive a lowercase `cloud-<environmentId>`).

## Security

- Single secret in cluster containing one API token
- No plaintext secrets in repo (all secrets are SOPS‑encrypted)
- Image version pinned for operator; consider pinning tunnel image explicitly (avoid `:latest`)

## Gaps / Next Steps

1. Add network egress restrictions (currently open)
2. Token rotation procedure (dual secret + phased CR update)
3. PodDisruptionBudget for operator & tunnel
4. Optional metrics collection for tunnel (if exposed)

## Summary

Lean setup: operator + one CR + one secret. Everything else is upstream controller responsibility.


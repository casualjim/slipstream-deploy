# Operations Runbook (Bootstrap)

> Philosophy: Keep human steps minimal; each block here should evolve into an automated workflow (script or controller). If a procedure needs >1-2 manual commands, create an issue to automate.

## Index
1. NATS (Synadia) Credential Rotation
2. Restate Bearer Token Rotation
3. Step CA Provisioner Password Rotation (Already Partially Documented)
4. Cloudflare API Token Rotation
5. SigNoz API Key Rotation
6. Validation: Connectivity Smoke Tests

---
## 1. NATS (Synadia) Credential Rotation
Goal: Replace creds for `wasmcloud` & `restate` users with zero downtime.

Steps:
1) Update SOPS‑encrypted Secrets under `k8s/layers/platform-infra/overlays/<env>/platform/nats-*-creds.yaml` with new `.creds` content.
2) Apply:
```sh
mise deploy:promote --environment <env> --provider <provider>
```
Prereqs:
- Generate new creds via Synadia portal or `nsc`.
- Keep old creds valid until rollout completes.
Post:
- After rollout success, revoke old users in Synadia.
Automation Target: Script wrapper validating subject permissions before apply.

## 2. Restate Bearer Token Rotation
1) Update SOPS‑encrypted Secret in `k8s/layers/platform-infra/overlays/<env>/restate-*/signing-key.yaml` or env token Secret as appropriate.
2) Apply with `mise deploy:promote --environment <env> --provider <provider>`.
Post: Remove old token in Restate Cloud console.
Automation Target: Add drift detector to alert if token age > 90d.

## 3. Step CA Provisioner Password Rotation
1) Update `k8s/layers/cloud-infra/overlays/<env>/cert-manager/step-provisioner-password.yaml` via SOPS.
2) Re‑apply with `mise deploy:promote --environment <env> --provider <provider>`.
Optional: Force re-issue critical certs (delete specific Certificate objects) if immediate rotation required.
Automation Target: Controller issuing expiring certs pre-rotation.

## 4. Cloudflare API Token Rotation
1) Update `k8s/layers/cloud-infra/overlays/<env>/ingress/cloudflare-token-ingress.yaml` and/or `.../cert-manager/cloudflare-token.yaml` via SOPS.
2) Re‑apply with `mise deploy:promote --environment <env> --provider <provider>`.
Post: Revoke old token in Cloudflare dashboard.
Automation Target: Expiry check workflow.

## 5. SigNoz API Key Rotation
1) Update `k8s/layers/cloud-infra/overlays/<env>/observability/signoz-api-key.yaml` via SOPS.
2) Re‑apply with `mise deploy:promote --environment <env> --provider <provider>`.
Post: Remove old key in SigNoz.
Automation Target: Telemetry ingestion 401 alerting.

## 6. Validation: Connectivity Smoke Tests
(Automate via future GitHub Action.) For now minimal manual probes (replace placeholder hostnames):
```sh
# NATS auth (should connect & exit cleanly)
nats bench pub --server "$NATS_URL" --creds new-wasmcloud.creds test.subject 1 || echo "NATS publish failed"

# Restate tunnel endpoint health (HTTP 200 expected)
curl --fail --silent --show-error "https://tunnel.$REGION.restate.cloud/$ENV_ID/$TUNNEL_NAME/health" || echo "Restate tunnel health check failed"
```
Automation Target: Add `make smoke` task + scheduled CI.

---
## Amend / Extend
Submit PRs to append new sections; each should:
- State goal.
- Provide a single compound command (chain with `&&` if needed).
- Note post-rotation cleanup.
- Define automation target.

---
Maintainer: Replace this file once workflows encoded (GitHub Actions / controllers).

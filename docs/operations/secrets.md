## Secrets & History Hygiene

This repository had its initial development history rewritten before first push to remove any chance of latent secret exposure.

### Current Sources of Secrets
| Source | Usage |
|--------|-------|
| SOPS‑encrypted files under `k8s/layers/**/overlays/*/*` | Cloudflare token, Step CA data, SigNoz API key, NATS creds |
| SOPS‑encrypted files under `tofu/infra/secrets/*.yaml` | Infra bootstrap inputs (operators only) |
| Local generation (scripts/setup-pki.sh) | Temporary PKI material (never committed) |

### Policy
1. No plaintext secrets in Git history or working tree.
2. All sensitive config values enter runtime via SOPS‑encrypted Kubernetes Secrets or OpenTofu inputs.
3. No plaintext secrets in repo; do not add provider credentials to state or logs.
4. Any accidental commit of a secret triggers immediate rotation + history rewrite (if not yet pushed) or revocation + force-push mitigation (if already pushed to a private remote), or full invalidation (if public).

### Pre‑Push Checklist
- [ ] `git grep -I -n "BEGIN .*PRIVATE KEY"` returns nothing
- [ ] `git grep -i cloudflareApiToken` does not show values (only code references)
- [ ] `git grep -I -n "BEGIN .*PRIVATE KEY"` returns nothing
- [ ] `gitleaks detect --no-git --config .gitleaks.toml` passes

### Running Secret Scan
```sh
gitleaks detect --config .gitleaks.toml
```

### History Rewrite Procedure (Already Performed Initially)
1. Create safety backup: `git branch backup/original-main`
2. Orphan branch: `git checkout --orphan new-main`
3. Stage clean tree: `git add . && git commit -m "Initial commit"`
4. Delete old branch: `git branch -D main`
5. Rename: `git branch -m main`
6. Hard prune: `git reflog expire --expire=now --all && git gc --prune=now --aggressive`
7. First push (protected main): `git push origin main` (after creating remote)

If any secrets had been present, rotate them now (Cloudflare, Step CA provisioner password, SigNoz API key, Vultr API key).

### Rotation Quick Reference
| Secret | Rotate Action |
|--------|---------------|
| Cloudflare API token | Create new token with same scopes, update SOPS‑encrypted Secret, delete old |
| Vultr API key | Regenerate key, update SOPS‑encrypted Secret or TF var, revoke old |
| Step provisioner password | Generate new strong password, update SOPS Secret; re‑issue certs if needed |
| SigNoz API key | Create new key in SigNoz UI, update SOPS Secret, revoke old |

### Adding New Secrets
Place a new Secret manifest under the appropriate overlay and encrypt with SOPS (AWS KMS as per `.sops.yaml`). Preferred filenames: `cloudflare-token.yaml`, `step-provisioner-password.yaml`, `signoz-api-key.yaml`, `nats-*.yaml`.

### Incident Response (If Secret Leaks After Push)
1. Revoke & rotate secret immediately.
2. Commit removal (if file), force-push only if private & acceptable; otherwise treat as fully compromised.
3. Audit access logs / API usage.
4. Document the incident in an internal runbook entry.

### Tooling Roadmap
- CI job running `gitleaks detect --config .gitleaks.toml` (pending addition)
- Optional pre-commit hook for local enforcement.

---
Maintainer: Update this document when secret handling process changes.

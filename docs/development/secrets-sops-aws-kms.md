# Secrets Management with SOPS + AWS KMS

This guide explains how to store and use secrets (Cloudflare token, Vultr API key, Step CA data, SigNoz API key, NATS creds) with SOPS encrypted by AWS KMS.

## Prerequisites
- AWS account with permissions for KMS (CreateKey, DescribeKey, Encrypt/Decrypt)
- AWS CLI configured (`aws configure`)
- Project checked out locally

## 1) Create an AWS KMS key
```sh
aws kms create-key \
  --description "SOPS secrets for slipstream-deploy" \
  --key-usage ENCRYPT_DECRYPT \
  --key-spec SYMMETRIC_DEFAULT
```
Note the returned Key ARN, e.g.:
```
arn:aws:kms:us-west-2:ACCOUNT_ID:key/KEY_ID
```

Optionally add an alias for easier reference:
```sh
aws kms create-alias \
  --alias-name alias/slipstream-sops \
  --target-key-id KEY_ID
```

## 2) Configure `.sops.yaml`
Add a creation rule pointing to your KMS key for the target file paths. This repo already includes `.sops.yaml` with rules for `tofu/infra/secrets/*.yaml` and kustomize overlay secrets. Update the KMS ARN to your key if needed.

## 3) Create or edit a SOPS‑encrypted Secret
Example: create Cloudflare API token Secret for cert‑manager overlay (dev):

```sh
cat > k8s/layers/cloud-infra/overlays/dev/cert-manager/cloudflare-token.yaml <<'YAML'
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
stringData:
  token: "YOUR_TOKEN"
YAML

sops --encrypt --in-place k8s/layers/cloud-infra/overlays/dev/cert-manager/cloudflare-token.yaml
```

## 4) Deploy with mise tasks
Render/preview/apply with mise; ksops will decrypt during build:

```sh
mise deploy:build --environment dev --provider vultr
mise deploy:preview --environment dev --provider vultr
mise deploy:promote --environment dev --provider vultr
```

## 5) OpenTofu inputs
OpenTofu reads SOPS files under `tofu/infra/secrets/*.yaml`. Ensure those files are encrypted with the same KMS key as configured in `.sops.yaml`.

## 6) Rotating a secret
Edit the Secret and re‑encrypt in place:
```sh
sops --decrypt --in-place k8s/layers/cloud-infra/overlays/dev/cert-manager/cloudflare-token.yaml
# edit token value safely
sops --encrypt --in-place k8s/layers/cloud-infra/overlays/dev/cert-manager/cloudflare-token.yaml
mise deploy:promote --environment dev --provider vultr
```

## Notes
- SOPS encrypts secrets at rest; AWS KMS manages the underlying encryption keys.
- Grant your team access to the KMS key via IAM. Distribute only encrypted files in the repo.
- Avoid committing secrets or printing them; use `--show-secrets` only when necessary.

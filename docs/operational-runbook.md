# Operational runbook

This runbook describes the common operator workflows for bootstrapping the
cluster and managing the platform manifests. It assumes operator-level
credentials (Vultr API key, SOPS decryption keys, Cloudflare token for DNS
challenges, etc.).

Bootstrap cluster (one-time per environment)

1. Prepare backend.hcl for OpenTofu remote state. Example backends are
  documented in tofu/infra/README.md. Do not commit backend.hcl.

2. Ensure you have SOPS keys available for decrypting tofu/infra/secrets.

3. Apply the infra OpenTofu root:

  cd tofu/infra
  tofu init -backend-config=backend.hcl
  tofu apply

4. Confirm outputs exist (sensitive): kubeconfig_decoded, cloudflare_api_token,
   step_ca_url, step_root_ca_pem, step_provisioner_kid/password, nats creds.

Fetch kubeconfig

- The repository includes a helper to fetch kubeconfig using the vultr CLI:

  mise fetch-kubeconfig --cluster slipstream-dev-cluster

  This writes decoded kubeconfig to ~/.kube/config.

- Alternatively, use `vultr kubernetes list --output json` to list clusters and `vultr kubernetes kubeconfig <id>` to obtain the kubeconfig manually.

Deploying tofu with mise (apply → merge kubeconfigs → promote)

- The repo uses mise for build/deploy tasks. To provision clusters (OpenTofu) and promote platform manifests across providers the short pattern is:

```sh
for provider in vultr ovh; do
  mise deploy:tofu:apply --provider "$provider" --environment "dev"
  mise deploy:tofu:kubeconfig --provider "$provider" --environment "dev"
done

mise merge-kubeconfigs

for ctx in $(kubectl config get-contexts -o name); do
  # We need to apply this at least 3 times to get all the manifests accepted in the cluster.
  for _ in {1..3}; do
    mise deploy:promote --provider "$provider" --environment "dev" --context "$ctx"
    sleep 30s
  done

  # overwrite the wasmcloud host config, with a mtls capable one
  kubectl apply -f /Users/ivan/github/casualjim/slipstream-deploy/k8s/layers/platform-infra/overlays/dev/platform/nats-leaf-config.yaml
  kubectl -n platform rollout restart ds wasmcloud-host

done

```



Deploy platform (kustomize)

- Render manifests:
  mise deploy:build --environment dev

- Preview (server-side dry run):
  mise deploy:preview --environment dev

- Promote (apply changes):
  mise deploy:promote --environment dev

Notes on apply behavior

- Applies are server-side (kubectl apply --server-side) with --force-conflicts
  and --wait=true. The helper uses a 60s timeout; large installs or CRD
  installs may require manual kubectl apply or extended wait logic.
- The build step uses ksops via an ephemeral plugin path to allow decryption of
  secrets during kustomize build. Ensure ksops binary is available on PATH or
  that mise which ksops resolves to a valid binary.

Verification checklist (post-deploy)

- [ ] Namespaces created (kustomize overlays include known namespaces; confirm)
- [ ] cert-manager is running and has issued ClusterIssuers/Issuers as expected
- [ ] ingress controller (ingress-nginx) is available and has the public IP
- [ ] sample-app (k8s/verification or sample-app.yaml) can be created and is
      reachable via its Ingress with a valid public cert
- [ ] NATS pods and statefulsets are ready (if deployed) and secrets mounted
- [ ] Step CA resources are available to cert-manager (Step ClusterIssuer)
- [ ] Monitoring/observability components (if enabled) are running

Troubleshooting tips

- ksops / kustomize build fails with plugin errors: ensure KUSTOMIZE_PLUGIN_HOME is writable and ksops binary is present.
- Certificate issuance failures: check Cloudflare token (tofu/infra reads
  this from SOPS) and DNS zone configuration.
- Long waits during apply: server-side apply waits for resources for up to 60s
  — if CRD installs or controllers take longer, apply CRDs manually first and
  re-run promote.
- Secrets not mounted: verify the ksops decryption was successful during build
  and that the resulting secret names match the manifests.

Rollbacks

- Kubernetes resources can be rolled back using `kubectl rollout undo` for
  Deployments or by re-applying prior manifest versions. The repo does not
  include automated Blue/Green or canary tooling; consider using annotation or
  labels to mark versions for manual rollback.

Maintenance & upgrades

- Upgrade strategy: update charts/values in k8s/layers and test with the
  verification manifests. Use preview before promote.
- When changing Step CA provisioner credentials or root CA, coordinate cert
  rotation for internal services and follow procedures in docs/pki.md.

Human checks required (cannot be automated by the repo)

- Backend.hcl content and remote state access
- SOPS key access and decryption ability
- Vultr API key, Cloudflare account tokens

Contact & support

- See docs/ADR and docs/architecture for historical decisions and design
  rationale.

Last updated: 2025-08-13

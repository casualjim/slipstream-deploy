# PKI (Current Implementation)

Authoritative details moved to `docs/architecture.md` (sections 4 & 5). This file provides an operational quick reference for the existing hosted Smallstep CA + cert-manager + step-issuer integration.

## 1) Create a Smallstep CA and JWK provisioner

You must create a CA in the Smallstep application (cloud or self‑hosted). Then create a JWK provisioner that cert-manager (step-issuer) will use.

Example to add a JWK provisioner named “workloads” with a 30‑day default x509 duration:
```
step ca provisioner add workloads --type JWK --create --x509-default-dur 720h
```

Record the following from the provisioner:
- Provisioner name (e.g., workloads)
- Provisioner KID
- Provisioner password (used to decrypt the JWK private key)

Also obtain:
- CA URL, e.g. https://ca.example.com:9000
- Root or chain PEM used to validate the CA’s TLS endpoint

## 2) Provide secrets via SOPS (kustomize overlays)

Store these items in SOPS‑encrypted Secret manifests under your environment overlay:
- Smallstep CA base URL
- Root or chain PEM for CA TLS endpoint
- JWK provisioner KID
- JWK provisioner password

Locations (per `.sops.yaml` rules):
- `k8s/layers/cloud-infra/overlays/<env>/cert-manager/step-root-ca-pem-cert-manager.yaml`
- `k8s/layers/cloud-infra/overlays/<env>/cert-manager/step-provisioner-password.yaml`
- `k8s/layers/cloud-infra/overlays/<env>/cert-manager/step-cluster-issuer.yaml`

These are decrypted during `mise deploy:*` via ksops.

## 3) What gets installed

Kustomize (via mise tasks) installs:
- Namespace `cert-manager`.
- Helm chart `cert-manager` with CRDs.
- Helm chart `step-issuer` controller.
- A `StepClusterIssuer` (cluster‑scoped) named `step-cluster-issuer` configured from SOPS‑encrypted Secrets.

Notes:
- The CRD requires `provisioner.name`, `provisioner.kid`, and `provisioner.passwordRef`.
- The issuerRef used by Certificates is:
  - group: `certmanager.step.sm`
  - kind: `StepClusterIssuer`
  - name: `step-cluster-issuer`

## 4) Requesting internal certificates (cert-manager)

Create Certificates that reference the StepClusterIssuer. Example:
```
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-service-internal-mtls
  namespace: default
spec:
  secretName: my-service-tls
  issuerRef:
    name: step-internal
    kind: StepClusterIssuer
    group: certmanager.step.sm
  commonName: my-service.default.svc.cluster.local
  dnsNames:
    - my-service.default.svc
    - my-service.default.svc.cluster.local
  duration: 2160h    # 90d
  renewBefore: 720h  # 30d
  privateKey:
    algorithm: RSA
    size: 2048
  usages:
    - server auth
    - client auth
```

This will produce a Secret named my-service-tls containing:
- tls.key — private key
- tls.crt — leaf certificate
- ca.crt — CA chain

## 5) Trust distribution

Workloads that validate peer certificates should trust the CA bundle:
- Option A: mount the PEM bundle through a ConfigMap
- Option B: distribute via your base image or initContainer

We previously described a projected trust bundle. You can still publish a ConfigMap in kube-system and mount at /etc/pki/step if desired.

## 6) Operational guidance

- Provisioner rotation:
  - Rotate the JWK provisioner password per your security policy; update step:provisionerPassword and re‑apply
- CA bundle updates:
  - If the CA chain changes, update the SOPS‑encrypted root CA PEM and re‑apply; the issuer will reconcile.
- Auditing:
  - Monitor the step-issuer controller logs in the cert-manager namespace for issuance errors

## 7) Troubleshooting

- CRD not found errors:
  - Ensure step‑issuer Helm release is fully ready before creating StepClusterIssuer (first apply may need a second run once CRDs are registered).
- spec.caBundle must be bytes:
  - We base64-encode root PEM in code to satisfy “format: byte”
- spec.provisioner.token field not declared:
  - The StepClusterIssuer CRD does not support token/audience (OIDC). Use JWK (name/kid/passwordRef)
- Certificate not Ready:
  - Check CertificateRequest and step-issuer logs
  - Verify provisionerKid/password and Secret passwordRef linkage

## 8) Notes / Out of Scope

We intentionally do NOT run an in‑cluster step‑ca today. Migration considerations (HA, backups, provisioner rotation automation) live in `docs/architecture.md#11-deferred--future`.

## 9) Validation checklist

- Controllers up:
  - kubectl --namespace cert-manager get pods
  - kubectl get crds | grep stepclusterissuers.certmanager.step.sm
- Issuer Ready:
  - kubectl get stepclusterissuer step-internal --output yaml | yq '.status'
- Certificate issuance:
  - kubectl --namespace default get certificate my-service-internal-mtls --output yaml
  - kubectl --namespace default get secret my-service-tls --output yaml (tls.crt, tls.key, ca.crt)

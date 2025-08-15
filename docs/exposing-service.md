# Exposing a Service (ingress-nginx) with Public HTTPS + Upstream mTLS

This guide shows how to expose a Kubernetes workload publicly (Let's Encrypt DNS‑01 via cert-manager + Cloudflare) while enforcing mutual TLS on the hop from the ingress-nginx controller to your backend service.

## Prerequisites
* Platform manifests applied (ingress-nginx, cert-manager, step-issuer controller, `step-cluster-issuer`, `ingress-upstream-client` Certificate, `step-root-ca` Secret, external-dns, Cloudflare token Secret) via mise tasks.
* Valid Step CA & Cloudflare credentials provided via SOPS‑encrypted Secrets in overlays.
* A hostname in the managed Cloudflare zone (e.g. `hello.dev.knub.ai`).
* The following Secrets exist:
  * `ingress-nginx/step-root-ca` – CA bundle for upstream verification.
  * `ingress-nginx/ingress-upstream-client` – client certificate presented by ingress controller.

## 1. Request an Internal Server Certificate
Issue a server certificate for the Service (signed by the StepClusterIssuer). Durations follow the defaults in `config.k8s.certificates` (currently 720h / renew 240h):
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-api-mtls
  namespace: default
spec:
  secretName: my-api-tls
  issuerRef:
    name: step-cluster-issuer
    kind: StepClusterIssuer
    group: certmanager.step.sm
  commonName: my-api.default.svc.cluster.local
  dnsNames:
    - my-api.default.svc
    - my-api.default.svc.cluster.local
  duration: 720h         # 30d (matches provisioner policy window)
  renewBefore: 240h      # 10d early renewal
  privateKey:
    algorithm: Ed25519
  usages:
    - server auth
```

## 2. Deploy Your Application Pod
Mount the issued TLS secret and configure the server to require (verify) a client certificate (the ingress controller's client cert):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-api
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels: { app: my-api }
  template:
    metadata:
      labels: { app: my-api }
    spec:
      containers:
        - name: app
          image: nginx:1.25-alpine
          ports:
            - containerPort: 8443
          volumeMounts:
            - name: tls
              mountPath: /etc/tls
              readOnly: true
          command: ["/bin/sh","-c"]
          args:
            - |
              cat <<'EOF' >/etc/nginx/conf.d/default.conf
              server {
                listen 8443 ssl;
                ssl_certificate /etc/tls/tls.crt;
                ssl_certificate_key /etc/tls/tls.key;
                ssl_client_certificate /etc/tls/ca.crt; # from cert secret
                ssl_verify_client on;                   # require ingress-nginx client cert
                location / { return 200 'ok'; }
              }
              EOF
              exec nginx -g 'daemon off;'
      volumes:
        - name: tls
          secret:
            secretName: my-api-tls
```

## 3. Service (Cluster Internal TLS Upstream)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-api
  namespace: default
spec:
  selector: { app: my-api }
  ports:
    - name: https
      port: 443
      targetPort: 8443
```

## 4. Ingress (Public HTTPS + Upstream mTLS)
Using ingress-nginx. Public certificate is issued by cert-manager via the `letsencrypt-dns01` ClusterIssuer and external-dns creates the DNS record.

Key annotations for upstream mTLS:
* `kubernetes.io/ingress.class: nginx`
* `cert-manager.io/cluster-issuer: letsencrypt-dns01`
* `nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"`
* `nginx.ingress.kubernetes.io/proxy-ssl-secret: ingress-nginx/ingress-upstream-client`
* `nginx.ingress.kubernetes.io/proxy-ssl-verify: "on"`
* `nginx.ingress.kubernetes.io/proxy-ssl-verify-depth: "2"`
* `nginx.ingress.kubernetes.io/proxy-ssl-trusted-ca: ingress-nginx/step-root-ca`
* `nginx.ingress.kubernetes.io/proxy-ssl-server-name: "on"`
* `nginx.ingress.kubernetes.io/proxy-ssl-name: my-api.default.svc.cluster.local`

Example:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-api
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-dns01
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/proxy-ssl-secret: ingress-nginx/ingress-upstream-client
    nginx.ingress.kubernetes.io/proxy-ssl-verify: "on"
    nginx.ingress.kubernetes.io/proxy-ssl-verify-depth: "2"
    nginx.ingress.kubernetes.io/proxy-ssl-trusted-ca: ingress-nginx/step-root-ca
    nginx.ingress.kubernetes.io/proxy-ssl-server-name: "on"
    nginx.ingress.kubernetes.io/proxy-ssl-name: my-api.default.svc.cluster.local
spec:
  tls:
    - hosts:
        - my-api.dev.knub.ai
      secretName: my-api-public-tls
  rules:
    - host: my-api.dev.knub.ai
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-api
                port:
                  number: 443
```

### How it works
1. Client -> ingress-nginx: Public TLS cert (ACME via cert-manager) terminates.
2. ingress-nginx -> backend: Presents client cert from `ingress-upstream-client`; validates backend server cert against `step-root-ca`.
3. Backend verifies client certificate (must enable `ssl_verify_client on;`).

## 5. (Optional) Direct Service-to-Service mTLS
For direct internal calls, issue client certs (add `client auth` to usages or a separate Certificate). Enforce peer verification in the server (nginx `ssl_verify_client on;`, gRPC TLS credentials, etc.).

## 6. Rotation & Renewal
cert-manager renews before `renewBefore` (default 240h). For forced rotation: delete the secret; cert-manager re-issues. The ingress controller will pick up new secrets automatically.

## 7. Hardening Checklist
| Control | Status |
|---------|--------|
| Require ingress-nginx client cert | Yes (`ssl_verify_client on`) |
| Restrict ingress traffic (NetworkPolicy) | Recommended |
| Distinct client cert per service | Optional (future) |
| Pin client cert SPKI | Optional (nginx `ssl_trusted_certificate`) |
| Limit cipher suites / TLS versions | Configure server (not shown) |

## 8. Troubleshooting
| Symptom | Check |
|---------|-------|
| 404 / pending DNS | `kubectl logs --namespace ingress-nginx deploy/external-dns` for record creation |
| Ingress public TLS fails | `kubectl describe certificate <public-cert>` / cert-manager & controller logs; Cloudflare token scope |
| Upstream mTLS fail | Backend pod logs (client cert required); verify Ingress annotations & secrets present |
| Cert not issued | `kubectl describe certificate <name>` + step-issuer controller logs |
| Client cert not presented | Inspect ingress controller pod logs; ensure `ingress-upstream-client` secret exists |

---
See `docs/architecture.md` for broader context.

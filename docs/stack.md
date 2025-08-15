# Slipstream Stack (Wishlist)

## Goals
- Agentic compute control plane; zero trust; multi‑region
- GitHub Actions + kustomize; low ops
- AI agents can write code and host it transparently

## Core Runtime
- wasmCloud lattice over NATS (Synadia leaf nodes per region)
- Durable orchestration via Restate; handlers implemented as wasmCloud actors

## Messaging
- NATS with JetStream; regional leaf nodes to Synadia
- mTLS everywhere; per‑subject authz; backpressure

## Ingress & TLS
- Traefik (LoadBalancer via Vultr CCM)
- ACME for public certs via Cloudflare DNS‑01 (Traefik only; no cert-manager)
- Internal mTLS: step-ca (HA in Kubernetes) + autocert
- Zero trust: enforce mTLS for intra‑cluster and inter‑region traffic

## Secrets
- SOPS‑encrypted manifests to render K8s Secrets at deploy
- Consider External Secrets only if in‑cluster sync is needed

## Networking
- VKE Calico CNI; Calico NetworkPolicy/GlobalNetworkPolicy for isolation
- No service mesh initially; Linkerd optional later

## Observability
- SigNoz via OpenTelemetry Collector (traces/metrics/logs)
- Dashboards/alerts for NATS, wasmCloud, Restate, ingress; SLOs

## AuthN/AuthZ
- User-facing: WorkOS/Stytch (OIDC/SAML, MFA)
- Service identity: step‑issued mTLS certs; NATS/wasmCloud claims
- Kubernetes RBAC; namespace tenancy; NetworkPolicies

## Supply Chain
- Private registry; image signing (cosign); policy (Kyverno/OPA); SBOM

## CI/CD
- GitHub Actions running mise tasks (`deploy:build/preview/promote`)
- Environments per region; secrets via SOPS

## Data & Storage
- CSI for object/block as needed; backups (Velero optional)

## Edge/Workers
- Regional clusters; autoscaling; taints/priority classes
- Optional SPIFFE/SPIRE for secure worker join later

## Open Questions
1) step-ca: single VM topology, provisioners (K8s SA only), rotation, trust bundles
2) Cloudflare DNS: zones/records, wildcard/split-horizon, API tokens/TTLs
3) wasmCloud + Restate: packaging agent‑generated code, registries, hot‑reload, lattice namespaces
4) NATS: accounts/users, subject conventions, JetStream limits/retention, multi‑region routing
5) Telemetry: SigNoz sizing, OTel pipelines, sampling, cardinality controls
6) Tenancy/governance: namespaces/quotas, RBAC, cost attribution
7) Supply chain: signing/attestation policy, provenance, SBOM
8) Worker onboarding: node classes, autoscaling, taints/tolerations, GPU support

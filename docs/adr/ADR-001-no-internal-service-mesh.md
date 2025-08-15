# ADR-001: No Internal Service Mesh

Date: 2025-08-09
Status: Accepted
Deciders: (add names)
Supersedes: None
Related: architecture.md Section 13

## Context
Traditional Kubernetes microservice stacks frequently add a service mesh (Istio/Linkerd) for mTLS, routing, retries, and observability. Our runtime consolidates on wasmCloud actors (message‑driven over NATS) plus Restate (Cloud) for durable workflows. Communication patterns avoid direct pod‑to‑pod L7 RPC except at ingress boundaries.

## Decision
Do NOT introduce an internal service mesh. Rely on:
* Existing PKI (Step + cert-manager) for mTLS.
* wasmCloud lattice (NATS) for location transparency + request routing.
* Restate Cloud for retries, idempotency, orchestration.
* Ingress + (optional future) API gateway layer for north‑south policy (rate limiting, authN/Z) if needed.

## Rationale
* Sidecar overhead provides minimal value for actor message passing (already asynchronous, decoupled).
* Mesh traffic management (canaries, splits) can be emulated at ingress (header / path based) or via versioned actors & workflow routing.
* Observability handled via OpenTelemetry in Restate gateways + structured actor logs + NATS metrics, without second control plane.
* Simplifies operational burden (fewer CRDs, upgrades, CVEs, cert rotations).

## When This May Be Revisited
* Need for uniform policy across large non-wasm legacy workloads (none planned).
* Requirement for fine‑grained egress policy enforcement not achievable via NetworkPolicies + NATS auth.
* Cross‑cluster traffic shaping beyond what ingress + NATS federation can provide.

## Mitigations / Ensuring Mesh Parity Where Needed
* Implement deny‑by‑default NetworkPolicies to replicate basic east‑west isolation (TODO).
* Adopt OpenTelemetry collectors early to aggregate traces and metrics.
* Standardize retry budgets / idempotency in Restate workflows so behavior is explicit (not implicit proxy retries).
* Use signed WASM modules + SBOM attestation (future supply chain work) to cover provenance aspects sometimes monitored via mesh.

## Consequences
* Lower infrastructure footprint and simpler troubleshooting path (no Envoy injection issues).
* Some mesh‑provided advanced traffic policies require manual implementation (e.g., progressive delivery via orchestrated ingress updates + workflow gating).

## Action Items
1. Add NATS deployment design doc (TODO).
2. Add ADR-002 (Restate Cloud integration pattern) – DONE.
3. Define wasmCloud host platform component (TODO).
4. Implement NetworkPolicies before first production release (TODO critical).

---

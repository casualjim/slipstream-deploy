# ADR-002: Restate Cloud Integration Pattern

Date: 2025-08-09
Status: Draft
Deciders: (add names)
Supersedes: None
Related: architecture.md Section 12, ADR-001 (No Internal Service Mesh)

## Context
We are adopting Restate Cloud for durable workflow/state orchestration instead of self-hosting. There is currently no native wasmCloud host integration (actors cannot yet be deployed *inside* Restate or vice versa), so we compose them via HTTP/gRPC boundaries and NATS events.

Requirements:
* Expose Restate service endpoints publicly (developer & application invocation) through existing nginx ingress with ACME TLS.
* Secure public exposure with mTLS internally (ingress -> service) and strong authN/Z (API key / identity token) at the edge.
* Allow Restate workflows/services to invoke wasmCloud handlers (HTTP capability providers) and publish/subscribe to NATS subjects.
* Manage secrets (Restate identity/API key, NATS creds) via SOPS‑encrypted Secrets without committing plaintext.
* Avoid premature coupling to any future wasmCloud<->Restate native integration but keep a clean abstraction boundary.

## Decision
Primary approach: leverage the official Restate Cloud Tunnel Client (operator-managed) to expose selected in-cluster services to Restate Cloud without creating public Kubernetes Ingress routes for those services.

Tunnel Client pattern:
1. Install Restate Operator (which deploys the tunnel client) with required env vars (`RESTATE_TUNNEL_NAME`, `RESTATE_ENVIRONMENT_ID`, `RESTATE_SIGNING_PUBLIC_KEY`, `RESTATE_BEARER_TOKEN`, `RESTATE_CLOUD_REGION`). If operating without the operator (not recommended), run the tunnel client manually with the same configuration.
2. Store bearer token & signing public key as SOPS‑encrypted Kubernetes Secrets (read-only, not logged).
3. Register cluster services with Restate Cloud using tunnel URL format (`https://tunnel.$REGION.restate.cloud/$ENV_ID/$TUNNEL_NAME/http/<service-dns>/<port>`); no Ingress objects required.
4. Set `RESTATE_REMOTE_PROXY=false` unless explicit need for local proxy endpoints; if enabled, restrict access via NetworkPolicies.
5. Workflows invoke services through the tunnel; services call Restate via SDK outbound over HTTPS (no need for gateway).
6. For wasmCloud interactions, services or workflows call HTTP capability providers (internal DNS) or use NATS events via existing creds.

Fallback (only if tunnel unsuitable / unavailable): implement lightweight stateless gateway/service Deployments in `restate` namespace that:
1. Terminate internal mTLS (server cert via StepClusterIssuer) and accept ingress upstream client cert.
2. Validate an API key / JWT for all external calls.
3. Relay to Restate Cloud APIs or SDK functions.
4. Propagate trace context (W3C traceparent) and perform cross-cutting concerns (auth augmentation, rate limiting).
5. Optionally produce / consume NATS events for async patterns.

## Rationale
* Keeps control of ingress security posture (rate limiting, WAF, future auth) in a single place (nginx + gateway).
* Minimizes secrets sprawl: only gateway pods mount Restate identity key; wasmCloud actors receive only what they need (no transitive propagation).
* Enables staged migration: if/when a native integration emerges, we can replace gateway logic without changing external contract.

## Alternatives Considered
| Alternative | Drawbacks |
|-------------|-----------|
| Direct client → Restate Cloud (bypass cluster ingress) | Fragmented DNS/certs, harder unified authZ, split monitoring paths. |
| Self-host Restate runtime | Additional operational burden (persistence, upgrades), less focus on core business value. |
| Mesh-based policy for egress to Restate | Rejected with ADR-001 (no mesh) – not needed for limited controlled egress. |

## Security Considerations
* API key stored as SOPS‑encrypted Secret; secret name convention: `restate-identity` in `restate` namespace.
* Key mounted read-only; fsGroup & runAsNonRoot enforced; no key in logs/metrics.
* Ingress rate limiting only relevant for any remaining public, user-facing endpoints; not needed for tunnel-mediated Restate traffic.
* Potential addition: rotate API key quarterly (SOPS Secret update + rollout).
* NetworkPolicy: allow ingress namespace → `restate` namespace, deny other pod access (TODO pending baseline NetworkPolicies rollout).
* NATS subjects: principle of least privilege; define an account limited to subjects with `restate.*` prefix for event bridging.

## Observability
* All gateway endpoints produce structured JSON logs (trace_id, span_id, workflow_id).
* OpenTelemetry collector (future) exports traces to chosen backend (OTLP -> vendor / OSS).
* Metrics: request counts, latency, error ratio, external Restate API call latency, NATS publish/consume metrics.

## Migration / Evolution
Phase 1 (current): Tunnel client in place; services registered via tunnel (no Ingress); workflows call through tunnel; direct service → wasmCloud handler calls internally.
Phase 2: Introduce NATS event bridge adapter (behind tunnel) for async invocation between workflows and actors (reduces synchronous coupling).
Phase 3: If native wasmCloud/Restate integration arrives, retire tunnel for those paths; migrate to lattice-based invocation; remove any fallback gateways if present.

## Consequences
* Slight added hop (gateway) but controlled surface area.
* Clear separation of secrets & responsibilities.
* Requires disciplined versioning of REST endpoints to preserve workflow determinism.

## Action Items
1. Platform component for Restate gateway Deployment + Secret + Ingress (scaffold).
2. Define NATS account/creds (subjects: `restate.events.*`, `workflow.outbox.*`).
3. Add NetworkPolicy baseline (deny-all + explicit allows).
4. Implement rate limiting annotations on Restate Ingress.
5. Add secret rotation runbook.
6. Add OpenTelemetry instrumentation guidelines for gateway.

## Open Questions
* Exact auth mechanism (API key vs signed JWT) – awaiting Restate Cloud finalized auth docs.
* Do we need separate gateways per domain (billing, user, etc.) for blast radius? (Leaning yes if growth > 3 domains.)
* Will we require bidirectional streaming (gRPC) – if so evaluate ingress controller support & potential switch.

---

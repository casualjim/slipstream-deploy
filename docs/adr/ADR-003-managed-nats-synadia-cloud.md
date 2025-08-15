# ADR-003: Managed NATS (Synadia Cloud) Adoption

Date: 2025-08-09
Status: Draft
Deciders: (add names)
Related: architecture.md Section 12, ADR-001, ADR-002

## Context
Initial plans assumed a self-hosted NATS cluster inside Kubernetes (JetStream enabled) to back the wasmCloud lattice and general pub/sub. Operating a reliable NATS cluster (upgrades, clustering, persistence, monitoring, security hardening) adds operational toil. Synadia Cloud offers managed NATS accounts with enterprise features, global routing, and built-in observability.

## Decision
Adopt Synadia Cloud as the NATS provider instead of self-hosting. All wasmCloud hosts and Restate gateway components connect to Synadia Cloud endpoints using per-component credentials (user creds or nkeys) with least-privilege subject permissions.

## Rationale
* Reduces operational overhead (no cluster lifecycle management, TLS cert rotation, JetStream storage management).
* Built-in metrics and account limits give quick capacity insights.
* Faster path to multi-region / federation if needed (Synadia infrastructure handles routing).
* Security posture improved via managed auth & revocation tooling.

## Implementation Outline
1. Create Synadia Cloud account & sub-account (if segmentation desired) for production vs non-prod.
2. Define subjects convention: `wasmcloud.*` for actor lattice traffic, `restate.events.*` for workflow events, `audit.*` reserved.
3. Create user creds:
   * `wasmcloud-host` (publish/subscribe `wasmcloud.>`; deny `audit.*`).
   * `restate-gateway` (pub `restate.events.*`, sub `wasmcloud.reply.*`).
   * `ops-observer` (read-only metrics subjects; no publish) – optional.
4. Store creds (nsc generated .creds or nkey seed) as SOPS‑encrypted Kubernetes Secrets.
5. Configure wasmCloud hosts with environment variables `NATS_URL`, `NATS_CREDS_FILE` referencing mounted secret.
6. Configure Restate gateways similarly when they need event emission.
7. Add automation (future) to rotate creds and trigger rolling restarts.

## Security Considerations
* Each component uses unique creds; compromised creds limit blast radius.
* Subject deny clauses prevent lateral misuse.
* Secrets never logged; mount with `readOnly: true`, fsGroup drop, runAsNonRoot.
* Rotation cadence: at least quarterly or on incident.

## Observability
* Rely on Synadia Cloud dashboards for connection counts, message rates, JetStream usage.
* Export critical metrics to internal monitoring (future: scrape Synadia API if provided or sidecar exporter).
* Correlate trace IDs by injecting them into NATS message headers (actor code guideline TBD).

## Alternatives
| Option | Drawbacks |
|--------|-----------|
| Self-host NATS | Operational toil, slower multi-region, more security surface. |
| Different managed broker (e.g., Kafka SaaS) | Not lattice-compatible for wasmCloud actor scheduling; heavier client footprint. |

## Consequences
* Vendor dependency on Synadia – mitigated by portability (can self-host NATS if required later with same subjects/creds model).
* Some advanced custom tuning less accessible (managed constraints) – acceptable vs toil.

## Action Items
1. Provision Synadia account & initial creds (TODO).
2. Add Secret schema and locations for NATS creds (TODO).
3. Implement wasmCloud host Deployment manifest referencing Synadia creds (TODO).
4. Document subject conventions in developer guide (TODO).
5. Rotation runbook (TODO).

## Open Questions
* Do we need separate accounts per environment or sub-accounts within one? (Evaluate cost vs isolation.)
* Will we enable JetStream persistence now or later (initially only for capabilities requiring durable streams)?
* Need dedicated leaf nodes near each region? (Defer until latency SLO defined.)

---

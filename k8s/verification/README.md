Ephemeral connectivity verification manifests

This folder contains throwaway manifests used to verify ingress connectivity patterns:
- Plain HTTP
- HTTPS at edge, HTTP upstream
- HTTPS at edge, HTTPS upstream (server-only)
- HTTPS at edge, mTLS upstream

They are not part of any kustomize overlay to avoid accidental deployment. Apply them ad-hoc when testing and delete afterwards.

Additional hello-worlds:
- wadm (wasmCloud): `wadm-hello.yaml` — deploy with wash: `wash app deploy k8s/verification/wadm-hello.yaml`, then port-forward a wasmCloud host pod to test on http://localhost:8080.
- Restate (via operator): `restate-hello.yaml` — apply with kubectl to create a minimal RestateDeployment against cluster `restate-dev`.

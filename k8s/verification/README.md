Ephemeral connectivity verification manifests

This folder contains throwaway manifests used to verify ingress connectivity patterns:
- Plain HTTP
- HTTPS at edge, HTTP upstream
- HTTPS at edge, HTTPS upstream (server-only)
- HTTPS at edge, mTLS upstream

They are not part of any kustomize overlay to avoid accidental deployment. Apply them ad-hoc when testing and delete afterwards.

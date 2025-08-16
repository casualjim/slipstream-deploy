---
description: Instructions to avoid complete stupidity and calamity
applyTo: '*'
---

- Give fact based answers WITH references.
- Only write clarifying comments about how the code functions.
- No Makefiles (use mise for tasks)
- No `any`, `unknown`, or untyped code
- FACT BASED means, if you use the word "might", you are doing the wrong thing and need more research use the tools: websearch, context7 and fetch
- Always use the `mise` command for building, deploying, or rendering manifests in this repository.
- Do NOT use plain `kustomize build` or `kubectl kustomize`—these will not produce correct results and may miss Helm charts or generators.
- Example: 

  To build for the dev environment, use:

  ```sh
  mise deploy:build --environment dev --provider vultr
  ```

- If you are troubleshooting or automating, always wrap your build/test/deploy steps with `mise`.
- when dealing with secrets. ALWAYS defer to the user, ask the user to execute commands but DO NOT operate on secrets directly.
- NEVER recommend that a dev stores secrets in local env vars, the only time when env vars are acceptable for secrets is inside a kubernetes pod.

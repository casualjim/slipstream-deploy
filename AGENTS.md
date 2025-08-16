# Instructions for LLM Agents

This file guides code-writing agents working in this repository.

## Stop pissing the dev off (hard constraints)

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


## Common Development Commands

| Task | Command | Notes |
|------|---------|-------|
| Render manifests | `mise deploy:build --environment <env> --provider <provider>` | Kustomize build with Helm and ksops enabled.
| Preview apply | `mise deploy:preview --environment <env> --provider <provider>` | Server-side dry run apply.
| Apply | `mise deploy:promote --environment <env> --provider <provider>` | Server-side apply with conflicts resolved.
| OpenTofu (infra) | From `tofu/infra`: `tofu init` · `tofu apply` | Use OpenTofu and SOPS for secrets.

## Architecture (Summary)

Authoritative details: `docs/architecture.md`.

Provisioning is split:
- Cloud infra: `tofu/infra` (Vultr VPC, VKE, firewall). Secrets read via SOPS.
- Cluster platform: `k8s/` kustomize overlays (cert-manager, step-issuer, ingress-nginx, etc.) rendered/applied via mise tasks.

Golden samples live in `k8s/verification/*.yaml`.

## Repository Layout (high-level)
```
slipstream-deploy/
├─ k8s/                  # Kustomize layers/overlays/stacks (platform manifests)
├─ tofu/infra/           # OpenTofu root for cloud bootstrap
├─ .mise/tasks/          # Deployment helpers (build/preview/promote)
├─ docs/                 # Architecture & operational docs
├─ tsconfig.json         # (Project defaults only; not used for infra)
└─ mise.toml             # Task definitions
```

## Default to using Bun instead of Node.js.

- Use `bun <file>` instead of `node <file>` or `ts-node <file>`
- Use `bun test` instead of `jest` or `vitest`
- Use `bun build <file.html|file.ts|file.css>` instead of `webpack` or `esbuild`
- Use `bun install` instead of `npm install` or `yarn install` or `pnpm install`
- Use `bun run <script>` instead of `npm run <script>` or `yarn run <script>` or `pnpm run <script>`
- Bun automatically loads .env, so don't use dotenv.

### APIs

- `Bun.serve()` supports WebSockets, HTTPS, and routes. Don't use `express`.
- `bun:sqlite` for SQLite. Don't use `better-sqlite3`.
- `Bun.redis` for Redis. Don't use `ioredis`.
- `Bun.sql` for Postgres. Don't use `pg` or `postgres.js`.
- `WebSocket` is built-in. Don't use `ws`.
- Prefer `Bun.file` over `node:fs`'s readFile/writeFile
- Bun.$`ls` instead of execa.

### Testing

# Instructions for LLM Agents

This file guides code-writing agents working in this repository.

# Developer Preferences (Hard Constraints)

- No Makefiles (use mise for tasks)
- No `any`, `unknown`, or untyped code
- No JVM usage
- No AWS hosting (exception: AWS KMS for SOPS only)
- Do not assume AWS usage
- Cloud provider: Vultr
- Object storage: Backblaze B2

Mantra: avoid default herd choices; prefer lean, counter‑culture tooling.

## Common Development Commands

| Task | Command | Notes |
|------|---------|-------|
| Render manifests | `mise deploy:build --environment <env> --provider <provider>` | Kustomize build with Helm and ksops enabled.
| Preview apply | `mise deploy:preview --environment <env> --provider <provider>` | Server-side dry run apply.
| Apply | `mise deploy:promote --environment <env> --provider <provider>` | Server-side apply with conflicts resolved.
| OpenTofu (infra) | From `tofu/infra`: `tofu init` · `tofu apply` | Use OpenTofu and SOPS for secrets.

## Architecture (Summary)

Authoritative details: `docs/architecture.md`.

Provisioning is split:
- Cloud infra: `tofu/infra` (Vultr VPC, VKE, firewall). Secrets read via SOPS.
- Cluster platform: `k8s/` kustomize overlays (cert-manager, step-issuer, ingress-nginx, etc.) rendered/applied via mise tasks.

Golden samples live in `k8s/verification/*.yaml`.

## Repository Layout (high-level)
```
slipstream-deploy/
├─ k8s/                  # Kustomize layers/overlays/stacks (platform manifests)
├─ tofu/infra/           # OpenTofu root for cloud bootstrap
├─ .mise/tasks/          # Deployment helpers (build/preview/promote)
├─ docs/                 # Architecture & operational docs
├─ tsconfig.json         # (Project defaults only; not used for infra)
└─ mise.toml             # Task definitions
```


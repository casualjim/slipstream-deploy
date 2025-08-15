# Instructions for LLM Agents

This file guides code-writing agents working in this repository.

# Developer Preferences (Hard Constraints)

- No Makefiles (use mise for tasks)
- No `any`, `unknown`, or untyped code
- No JVM usage
- No AWS hosting (exception: AWS KMS for SOPS only)
- Do not assume AWS usage
- Cloud provider: Vultr / OVH
- Object storage: Backblaze B2 / OVH

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


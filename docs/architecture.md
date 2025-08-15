# Slipstream Deploy — Architecture (source-verified)

## Table of contents

- [Slipstream Deploy — Architecture (source-verified)](#slipstream-deploy--architecture-source-verified)
  - [Table of contents](#table-of-contents)
  - [TL;DR](#tldr)
  - [High-level summary](#high-level-summary)
  - [Mermaid diagram](#mermaid-diagram)
  - [Kustomize structure](#kustomize-structure)
    - [Cloud-infra layer](#cloud-infra-layer)
    - [Platform-infra layer](#platform-infra-layer)
    - [Stacks (dev / preprod)](#stacks-dev--preprod)
    - [Verification / sample apps](#verification--sample-apps)
  - [What each stack deploys (high level)](#what-each-stack-deploys-high-level)
  - [How mise + ksops interact with kustomize](#how-mise--ksops-interact-with-kustomize)
  - [Maintainer checklist when editing kustomize](#maintainer-checklist-when-editing-kustomize)
  - [Files \& locations (quick map)](#files--locations-quick-map)
  - [Verified-by (file references)](#verified-by-file-references)
  - [Appendix: Common commands](#appendix-common-commands)
  - [Change log](#change-log)

## TL;DR

Slipstream-deploy provisions cloud infrastructure (Vultr) with OpenTofu and manages cluster platform manifests with kustomize. OpenTofu (tofu/infra) bootstraps the Vultr VPC, Kubernetes cluster, and supporting secrets; the cluster add-ons and application manifests live under k8s/ and are rendered/deployed via mise which runs kustomize with ksops for SOPS decryption.

## High-level summary

- Infrastructure (VMs, networks, Kubernetes cluster) = OpenTofu (tofu/infra)
- Platform and application manifests = kustomize under k8s/
- Secrets at rest = SOPS-encrypted YAML (tofu/infra/secrets and k8s overlays); ksops is used during render
- Tooling = mise tasks (in .mise/tasks) wrap kustomize and other steps; always use mise for builds/deploys

## Mermaid diagram

```mermaid
flowchart LR
  subgraph Operator
    A[Developer / Operator]
    A -->|run mise| B[mise tasks]
  end

  subgraph Repo
    B --> C[k8s/ (layers, overlays, stacks)]
  B --> D[tofu/infra]
    C --> E[kustomize + ksops]
  D --> F[OpenTofu state / Vultr]
  end

  subgraph Cloud
    F --> G[Vultr: VPC, K8s cluster, Firewall]
    E --> H[Kubernetes cluster]
    H --> I[Ingress, cert-manager, apps]
  end

  style Repo fill:#f9f,stroke:#333,stroke-width:1px
  style Cloud fill:#efe,stroke:#333,stroke-width:1px
```

## Kustomize structure

The repo uses a layers/overlays/stacks layout. Below is a source-verified mapping and short description for each major directory.

### Cloud-infra layer

- k8s/layers/cloud-infra/base/
  - cert-manager/: Base cert-manager resources (namespace, issuers)
    - Files: k8s/layers/cloud-infra/base/cert-manager/kustomization.yaml, issuers.yaml
  - ingress/: Base ingress-related resources and namespace
    - Files: k8s/layers/cloud-infra/base/ingress/kustomization.yaml
  - observability/: Base namespace and observability resources
    - Files: k8s/layers/cloud-infra/base/observability/kustomization.yaml
  - vultr/: cloud-provider-specific resources (CCM, storageclass, secrets-generator)
    - Files: k8s/layers/cloud-infra/base/vultr/kustomization.yaml, storageclass-nvme-wffc.yaml

- k8s/layers/cloud-infra/overlays/dev and overlays/preprod/
  - Provide environment-specific secrets and config for cert-manager, ingress, observability and vultr.
  - Examples:
    - k8s/layers/cloud-infra/overlays/dev/cert-manager/step-cluster-issuer.yaml
    - k8s/layers/cloud-infra/overlays/dev/ingress/ingress-upstream-mtls.yaml
    - k8s/layers/cloud-infra/overlays/dev/observability/signoz-api-key.yaml

### Platform-infra layer

- k8s/layers/platform-infra/base/
  - platform/: Namespace and base platform kustomization
    - Files: k8s/layers/platform-infra/base/platform/kustomization.yaml, namespace.yaml
  - restate-operator/: Helm chart + CRDs for the restate operator
    - Files: k8s/layers/platform-infra/base/restate-operator/kustomization.yaml and charts/*
  - restate/: Base restate CRs and supporting resources
    - Files: k8s/layers/platform-infra/base/restate/kustomization.yaml

- k8s/layers/platform-infra/overlays/dev and overlays/preprod/
  - Provide environment secrets, NATS credentials, platform certificates, and restate CR overrides.
  - Examples:
    - k8s/layers/platform-infra/overlays/dev/platform/nats-host-creds.yaml
    - k8s/layers/platform-infra/overlays/dev/restate-dev/cluster.yaml

### Stacks (dev / preprod)

- k8s/stacks/dev/kustomization.yaml — entrypoint composing cloud-infra and platform-infra with dev overlays.
- k8s/stacks/preprod/kustomization.yaml — entrypoint composing the preprod overlays.

### Verification / sample apps

- k8s/verification contains small sample apps and sanity checks for TLS/MTLS patterns. Use these to validate a cluster after deploying platform components.
  - Files: k8s/verification/sample-plain-app.yaml, sanity-tls-app.yaml, sanity-mtls-app.yaml

## What each stack deploys (high level)

- dev stack (k8s/stacks/dev/kustomization.yaml) composes:
  - cloud-infra: cert-manager (issuers), ingress config (upstream mTLS annotations), observability placeholders, Vultr CCM + storageclass
  - platform-infra: platform namespace, restate operator (CRDs + deployment), restate CRs, and NATS Helm chart + credentials for dev
  - optional verification manifests from k8s/verification

- preprod stack (k8s/stacks/preprod/kustomization.yaml) composes similar layers with preprod overlays applied (different secrets, certificates, ingress configs, NATS credentials)

## How mise + ksops interact with kustomize

- mise tasks call kustomize build while ensuring ksops (or a configured SOPS decryption tool) decrypts secrets on-the-fly where necessary. See .mise/tasks/deploy/* for the exact wrappers.
- Always use `mise deploy:build --environment <env>` to render manifests. This ensures overlay order, generators, and secrets handling match the promote/deploy flow.

## Maintainer checklist when editing kustomize

- Verify label/selector consistency between Deployments and Services
- Avoid :latest image tags; prefer pinned image tags
- Ensure containers include resource requests/limits and probes
- Add secrets through the appropriate environment overlay and do not hardcode secrets in base/ files
- Run `mise deploy:build --environment <env>` locally to validate rendering before opening a PR

## Files & locations (quick map)

- tofu/infra: OpenTofu modules and SOPS-encrypted secrets used to provision Vultr resources
- k8s/: Layered kustomize manifests for platform and applications (layers/overlays/stacks)
- .mise/tasks/: Scripts to render and apply manifests and fetch kubeconfig
- sample-app.yaml and k8s/verification/: Canonical examples and sanity check manifests

## Verified-by (file references)

- tofu/infra/main.tf
- tofu/infra/modules/vultr/main.tf
- tofu/infra/secrets/*
- .mise/tasks/deploy/*
- k8s/stacks/dev/kustomization.yaml
- k8s/stacks/preprod/kustomization.yaml
- k8s/layers/cloud-infra/base/* and overlays/*
- k8s/layers/platform-infra/base/* and overlays/*
- k8s/verification/*
- sample-app.yaml

## Appendix: Common commands

- Render k8s manifests for dev (render only):

```sh
mise deploy:build --environment dev
```

- Fetch kubeconfig (operator):

```sh
mise fetch-kubeconfig --cluster <cluster-name>
```

- Apply k8s manifests (operator):

```sh
mise deploy:promote --environment dev
```

## Change log

- 2025-08-13: Reconciled architecture doc to source; added Mermaid diagram and explicit file→claim mappings.
- 2025-08-14: Reorganized into structured Markdown, added Kustomize structure and detailed file mappings.

# OVH API Keys

OVH doesn’t have a “god mode” token, but you can create a Consumer Key with broad wildcard rules that effectively grant blanket access.

## What to do

Use the token generator for your endpoint (you’re on ovh-ca): https://ca.api.ovh.com/createToken/

Add these rules to cover all Cloud (safer: single project) APIs with full CRUD:

### Safer (single project)

**Methods**: `GET`, `POST`, `PUT`, `DELETE`
**Path**: `/cloud/project/${OVH_PROJECT_ID}/*`

### Blanket (all Cloud projects under the account)

**Methods**: `GET`, `POST`, `PUT`, `DELETE`
**Path**: `/cloud/*`

Generate the Consumer Key, store it in SOPS (tofu/infra/secrets/base.yaml under ovh.consumerKey).

## Why this works

OVH Consumer Keys are scoped by method and path patterns (supporting wildcards like ). Granting /cloud/ with all methods covers kube, nodepools, vRack private networks, subnets, gateways—everything the provider calls.
Terraform needs GET, POST, PUT, DELETE on those paths to import, read, create, update, and delete.
References

OVH API first steps and token rights: https://docs.ovh.com/ca/en/api/first-steps-with-ovh-api/
Token creation (CA): https://ca.api.ovh.com/createToken/
OVH Terraform provider resources (import formats): https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_project_kube#import and related pages

data "sops_file" "base" { source_file = "${path.module}/secrets/base.yaml" }

data "sops_file" "env" { source_file = "${path.module}/secrets/${terraform.workspace}.yaml" }

locals {
  # Keep only the secrets required by this infra: the Vultr API key
  vultr_api_key = data.sops_file.base.data["vultr.apiKey"]
}

provider "vultr" {
  api_key = local.vultr_api_key
}

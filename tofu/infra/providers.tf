data "sops_file" "base" { source_file = "${path.module}/secrets/base.yaml" }

data "sops_file" "env" { source_file = "${path.module}/secrets/${terraform.workspace}.yaml" }

locals {
  # Existing: Vultr API key
  vultr_api_key = try(data.sops_file.base.data["vultr.apiKey"], null)

  # OVH credentials (optionally provided via SOPS; env vars also supported)
  ovh_application_key    = try(data.sops_file.base.data["ovh.applicationKey"], null)
  ovh_application_secret = try(data.sops_file.base.data["ovh.applicationSecret"], null)
  ovh_consumer_key       = try(data.sops_file.base.data["ovh.consumerKey"], null)
}

provider "vultr" {
  api_key = local.vultr_api_key
}

provider "ovh" {
  endpoint            = var.ovh_endpoint
  application_key     = local.ovh_application_key
  application_secret  = local.ovh_application_secret
  consumer_key        = local.ovh_consumer_key
}

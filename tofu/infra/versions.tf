terraform {
  required_version = ">= 1.10.0"
  backend "s3" {} # B2 S3-compatible backend configured via -backend-config=backend.hcl
  required_providers {
    sops = { source = "carlpett/sops" }
    vultr = { source = "vultr/vultr" }
    cloudflare = { source = "cloudflare/cloudflare" }
    kubernetes = { source = "hashicorp/kubernetes" }
    helm = { source = "hashicorp/helm" }
    b2 = { source = "Backblaze/b2" }
  }
}

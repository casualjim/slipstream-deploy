#############################################
# Vultr Core Module (see original for comments)
#############################################
terraform {
  required_providers {
    vultr = {
    source  = "registry.opentofu.org/vultr/vultr"
      # optional version constraint to keep parity with root
      version = "~> 2.26"
    }
  }
}
variable "project" { type = string }
variable "environment" { type = string }
variable "region" { type = string }
variable "cluster_version" { type = string }
variable "node_pool_label" { type = string }
variable "node_plan" { type = string }
variable "node_quantity" { type = number }

locals {
  prefix = "${var.project}-${var.environment}"
}

resource "vultr_vpc" "this" {
  description = "${local.prefix}-vpc"
  region      = var.region
}
resource "vultr_kubernetes" "this" {
  region          = var.region
  label           = "${local.prefix}-cluster"
  version         = var.cluster_version
  enable_firewall = true
  vpc_id          = vultr_vpc.this.id

  node_pools {
    label         = var.node_pool_label
    plan          = var.node_plan
    node_quantity = var.node_quantity

  }
}

locals {
  kubeconfig_raw     = vultr_kubernetes.this.kube_config
  kubeconfig_decoded = try(base64decode(local.kubeconfig_raw), local.kubeconfig_raw)
}

output "vpc_id" {
  value = vultr_vpc.this.id
}
output "cluster_id" {
  value = vultr_kubernetes.this.id
}
output "firewall_group_id" {
  value = vultr_kubernetes.this.firewall_group_id
}
output "kubeconfig_decoded" {
  value     = local.kubeconfig_decoded
  sensitive = true
}

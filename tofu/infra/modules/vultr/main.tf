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
variable "enabled" {
  type    = bool
  default = true
}

locals {
  prefix = "${var.project}-${var.environment}"
}

resource "vultr_vpc" "this" {
  count       = var.enabled ? 1 : 0
  description = "${local.prefix}-vpc"
  region      = var.region
}
resource "vultr_kubernetes" "this" {
  count           = var.enabled ? 1 : 0
  region          = var.region
  label           = "${local.prefix}-cluster"
  version         = var.cluster_version
  enable_firewall = true
  vpc_id          = vultr_vpc.this[0].id

  node_pools {
    label         = var.node_pool_label
    plan          = var.node_plan
    node_quantity = var.node_quantity

  }
}

locals {
  kubeconfig_raw     = var.enabled ? vultr_kubernetes.this[0].kube_config : null
  kubeconfig_decoded = var.enabled ? try(base64decode(local.kubeconfig_raw), local.kubeconfig_raw) : null
}

output "vpc_id" {
  value = var.enabled ? vultr_vpc.this[0].id : null
}
output "cluster_id" {
  value = var.enabled ? vultr_kubernetes.this[0].id : null
}
output "firewall_group_id" {
  value = var.enabled ? vultr_kubernetes.this[0].firewall_group_id : null
}
output "kubeconfig_decoded" {
  value     = local.kubeconfig_decoded
  sensitive = true
}

# Baseline firewall rules (kept within Vultr module)
resource "vultr_firewall_rule" "allow_ssh" {
  count             = var.enabled ? 1 : 0
  firewall_group_id = vultr_kubernetes.this[0].firewall_group_id
  ip_type           = "v4"
  protocol          = "tcp"
  port              = "22"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  notes             = "Allow SSH"
}

resource "vultr_firewall_rule" "allow_http" {
  count             = var.enabled ? 1 : 0
  firewall_group_id = vultr_kubernetes.this[0].firewall_group_id
  ip_type           = "v4"
  protocol          = "tcp"
  port              = "80"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  notes             = "Allow HTTP"
}

resource "vultr_firewall_rule" "allow_https" {
  count             = var.enabled ? 1 : 0
  firewall_group_id = vultr_kubernetes.this[0].firewall_group_id
  ip_type           = "v4"
  protocol          = "tcp"
  port              = "443"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  notes             = "Allow HTTPS"
}

resource "vultr_firewall_rule" "allow_ssh_v6" {
  count             = var.enabled ? 1 : 0
  firewall_group_id = vultr_kubernetes.this[0].firewall_group_id
  ip_type           = "v6"
  protocol          = "tcp"
  port              = "22"
  subnet            = "::"
  subnet_size       = 0
  notes             = "Allow SSH (IPv6)"
}

resource "vultr_firewall_rule" "allow_http_v6" {
  count             = var.enabled ? 1 : 0
  firewall_group_id = vultr_kubernetes.this[0].firewall_group_id
  ip_type           = "v6"
  protocol          = "tcp"
  port              = "80"
  subnet            = "::"
  subnet_size       = 0
  notes             = "Allow HTTP (IPv6)"
}

resource "vultr_firewall_rule" "allow_https_v6" {
  count             = var.enabled ? 1 : 0
  firewall_group_id = vultr_kubernetes.this[0].firewall_group_id
  ip_type           = "v6"
  protocol          = "tcp"
  port              = "443"
  subnet            = "::"
  subnet_size       = 0
  notes             = "Allow HTTPS (IPv6)"
}

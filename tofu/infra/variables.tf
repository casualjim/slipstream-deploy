// migrated from tofu/variables.tf (infra subset only)
variable "project" {
  type    = string
  default = "slipstream"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "cloud" {
  description = "Target cloud provider: 'vultr' or 'ovh'"
  type        = string
  default     = "vultr"
  validation {
    condition     = contains(["vultr", "ovh"], var.cloud)
    error_message = "cloud must be one of: vultr, ovh"
  }
}
variable "vultr_region" {
  type    = string
  default = "lax"
}
variable "vultr_cluster_version" {
  type    = string
  default = "v1.33.0+3"
}
variable "vultr_node_pool_label" {
  type    = string
  default = "pool-2c4g"
}
variable "vultr_node_plan" {
  type    = string
  default = "vc2-2c-4gb"
}
variable "vultr_node_quantity" {
  type    = number
  default = 3
}

# OVH variables (from ovh-prep checklist)
variable "ovh_project_id" {
  description = "OVH Cloud project ID"
  type        = string
  default     = ""
}
variable "ovh_region" {
  description = "Primary region (e.g., BHS5)"
  type        = string
  default     = "BHS5"
}
variable "ovh_k8s_version" {
  description = "Managed Kubernetes version"
  type        = string
  default     = "1.33"
}
variable "ovh_cluster_name" {
  description = "Desired cluster name"
  type        = string
  default     = "slipstream-dev"
}
variable "ovh_node_flavor" {
  description = "Node flavor for the nodepool (e.g., b3-8)"
  type        = string
  default     = ""
}
variable "ovh_nodepool_size" {
  description = "Desired node count"
  type        = number
  default     = 3
}
variable "ovh_nodepool_autoscale" {
  description = "Enable autoscaling"
  type        = bool
  default     = true
}
variable "ovh_nodepool_min" {
  description = "Autoscaler min nodes"
  type        = number
  default     = 3
}
variable "ovh_nodepool_max" {
  description = "Autoscaler max nodes"
  type        = number
  default     = 5
}
variable "ovh_vrack" {
  description = "Whether to attach a private vRack network (boolean toggle, actual network wiring may occur post-provision)."
  type        = bool
  default     = true
}
variable "ovh_endpoint" {
  description = "OVH API endpoint (ovh-eu, ovh-ca, etc.)"
  type        = string
  default     = "ovh-ca"
}

variable "ovh_create_buckets" {
  description = "Create S3-compatible buckets for Restate state (2 buckets)"
  type        = bool
  default     = false
}
variable "ovh_bucket_region" {
  description = "Region for object storage buckets (e.g., BHS)"
  type        = string
  default     = "BHS"
}

variable "vrack_vlan_id" {
  type        = number
  description = "vRack VLAN ID for the private network"
  default     = 42
}
variable "private_subnet_cidr" {
  type        = string
  description = "CIDR for the private subnet (e.g., 10.42.0.0/24)"
}
variable "private_subnet_start" {
  type        = string
  description = "DHCP start IP for the subnet"
}
variable "private_subnet_end" {
  type        = string
  description = "DHCP end IP for the subnet"
}

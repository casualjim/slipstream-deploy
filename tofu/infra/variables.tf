// migrated from tofu/variables.tf (infra subset only)
variable "project" {
  type    = string
  default = "slipstream"
}
variable "environment" {
  type    = string
  default = "dev"
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


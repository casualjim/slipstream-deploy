module "vultr_core" {
  source = "./modules/vultr"

  project         = var.project
  environment     = var.environment
  region          = var.vultr_region
  cluster_version = var.vultr_cluster_version
  node_pool_label = var.vultr_node_pool_label
  node_plan       = var.vultr_node_plan
  node_quantity   = var.vultr_node_quantity
  enabled         = var.cloud == "vultr"
}

module "ovh_core" {
  source = "./modules/ovh"
  count  = var.cloud == "ovh" ? 1 : 0

  project            = var.project
  environment        = var.environment
  project_id         = var.ovh_project_id
  region             = var.ovh_region
  k8s_version        = var.ovh_k8s_version
  cluster_name       = var.ovh_cluster_name
  node_flavor        = var.ovh_node_flavor
  nodepool_size      = var.ovh_nodepool_size
  nodepool_autoscale = var.ovh_nodepool_autoscale
  nodepool_min       = var.ovh_nodepool_min
  nodepool_max       = var.ovh_nodepool_max
  vrack              = var.ovh_vrack
  create_buckets     = var.ovh_create_buckets
  bucket_region      = var.ovh_bucket_region
  # vRack private networking
  vrack_vlan_id        = var.vrack_vlan_id
  private_subnet_cidr  = var.private_subnet_cidr
  private_subnet_start = var.private_subnet_start
  private_subnet_end   = var.private_subnet_end
}


output "vpc_id" {
  value = var.cloud == "vultr" ? module.vultr_core.vpc_id : null
}

output "cluster_id" {
  value = var.cloud == "vultr" ? module.vultr_core.cluster_id : try(module.ovh_core[0].cluster_id, null)
}

output "kubeconfig_decoded" {
  value     = var.cloud == "vultr" ? module.vultr_core.kubeconfig_decoded : try(module.ovh_core[0].kubeconfig_decoded, null)
  sensitive = true
}

output "ovh_private_network_id" {
  value = var.cloud == "ovh" ? try(module.ovh_core[0].private_network_id, null) : null
}

output "ovh_private_subnet_id" {
  value = var.cloud == "ovh" ? try(module.ovh_core[0].private_subnet_id, null) : null
}

output "ovh_gateway_id" {
  value = var.cloud == "ovh" ? try(module.ovh_core[0].gateway_id, null) : null
}

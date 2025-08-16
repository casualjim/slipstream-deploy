// Additional nodepools resource block
// This file provides an example resource that can be used to provision
// extra nodepools after the initial cluster creation. It expects a map of
// nodepool definitions passed in via the `extra_nodepools` variable.

variable "extra_nodepools" {
  type    = map(object({
    name        = string
    flavor_name = string
    desired_nodes = number
    autoscale   = bool
    min_nodes   = number
    max_nodes   = number
  }))
  default = {}
}

resource "ovh_cloud_project_kube_nodepool" "extra" {
  for_each = var.extra_nodepools

  service_name = var.project_id
  kube_id      = ovh_cloud_project_kube.this.id
  name         = each.value.name
  flavor_name  = each.value.flavor_name
  desired_nodes = each.value.desired_nodes

  autoscale = each.value.autoscale
  min_nodes = each.value.min_nodes
  max_nodes = each.value.max_nodes
}

output "extra_nodepool_ids" {
  value = { for k, v in ovh_cloud_project_kube_nodepool.extra : k => v.id }
}

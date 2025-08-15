module "vultr_core" {
  source = "./modules/vultr"

  project              = var.project
  environment          = var.environment
  region               = var.vultr_region
  cluster_version      = var.vultr_cluster_version
  node_pool_label      = var.vultr_node_pool_label
  node_plan            = var.vultr_node_plan
  node_quantity        = var.vultr_node_quantity
}

# Add baseline firewall rules to the cluster's firewall group
resource "vultr_firewall_rule" "allow_ssh" {
  firewall_group_id = module.vultr_core.firewall_group_id
  ip_type           = "v4"
  protocol          = "tcp"
  port              = "22"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  notes             = "Allow SSH"
}

resource "vultr_firewall_rule" "allow_http" {
  firewall_group_id = module.vultr_core.firewall_group_id
  ip_type           = "v4"
  protocol          = "tcp"
  port              = "80"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  notes             = "Allow HTTP"
}

resource "vultr_firewall_rule" "allow_https" {
  firewall_group_id = module.vultr_core.firewall_group_id
  ip_type           = "v4"
  protocol          = "tcp"
  port              = "443"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  notes             = "Allow HTTPS"
}

resource "vultr_firewall_rule" "allow_ssh_v6" {
  firewall_group_id = module.vultr_core.firewall_group_id
  ip_type           = "v6"
  protocol          = "tcp"
  port              = "22"
  subnet            = "::"
  subnet_size       = 0
  notes             = "Allow SSH (IPv6)"
}

resource "vultr_firewall_rule" "allow_http_v6" {
  firewall_group_id = module.vultr_core.firewall_group_id
  ip_type           = "v6"
  protocol          = "tcp"
  port              = "80"
  subnet            = "::"
  subnet_size       = 0
  notes             = "Allow HTTP (IPv6)"
}

resource "vultr_firewall_rule" "allow_https_v6" {
  firewall_group_id = module.vultr_core.firewall_group_id
  ip_type           = "v6"
  protocol          = "tcp"
  port              = "443"
  subnet            = "::"
  subnet_size       = 0
  notes             = "Allow HTTPS (IPv6)"
}

output "vpc_id" {
  value = module.vultr_core.vpc_id
}

output "cluster_id" {
  value = module.vultr_core.cluster_id
}

output "kubeconfig_decoded" {
  value     = module.vultr_core.kubeconfig_decoded
  sensitive = true
}

terraform {
  required_version = ">= 1.3.0"
}

module "k3s_nodes" {
  source = "./modules/proxmox_vms"

  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret

  vm_nodes      = var.vm_nodes
  vm_config     = var.vm_config
  ssh_pub_key   = var.ssh_pub_key
  vm_password   = var.vm_password
  vm_user       = var.vm_user
}

module "k3s_bootstrap" {
  depends_on = [module.k3s_nodes]
  source = "./modules/k3s_bootstrap"

  k3s_token         = var.k3s_token
  master_nodes      = module.k3s_nodes.master_ips
  primary_master    = module.k3s_nodes.primary_master_ip
  vm_user           = var.vm_user
  ssh_priv_key      = var.ssh_priv_key
  registry_url      = var.registry_url
  registry_username = var.registry_username
  registry_password = var.registry_password
}

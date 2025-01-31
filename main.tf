terraform {
  required_version = ">= 1.3.0"
}

# Call Proxmox VM Module
module "k3s_nodes" {
  source = "./modules/proxmox_vms"

  pm_api_url         = var.pm_api_url
  pm_api_token_id    = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret

  vm_nodes   = var.vm_nodes
  vm_config  = var.vm_config
}

# Call K3s Bootstrap Module
module "k3s_bootstrap" {
  source = "./modules/k3s_bootstrap"

  k3s_token      = var.k3s_token
  master_nodes   = module.k3s_nodes.master_ips
  primary_master = module.k3s_nodes.primary_master_ip

  depends_on = [module.k3s_nodes]
}

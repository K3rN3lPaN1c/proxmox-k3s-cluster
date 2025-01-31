output "k3s_primary_master" {
  description = "Primary K3s master node IP"
  value       = module.k3s_bootstrap.primary_master_ip
}

output "k3s_master_nodes" {
  description = "All K3s master nodes IPs"
  value       = module.k3s_bootstrap.master_node_ips
}

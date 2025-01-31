output "primary_master_ip" {
  description = "IP address of the primary K3s master node"
  value       = var.primary_master
}

output "master_node_ips" {
  description = "List of all K3s master node IPs"
  value       = var.master_nodes
}

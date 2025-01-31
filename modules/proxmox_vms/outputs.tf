output "master_ips" {
  description = "List of all K3s master node IPs"
  value       = { for k, v in var.vm_config : k => v.static_ip }
}

output "primary_master_ip" {
  description = "IP address of the primary K3s master node"
  value       = var.vm_config["pub-k3s-01"].static_ip
}

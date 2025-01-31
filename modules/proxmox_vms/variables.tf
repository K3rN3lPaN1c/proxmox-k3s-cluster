variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
}

variable "pm_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "vm_nodes" {
  description = "Mapping of VM names to Proxmox nodes"
  type        = map(string)
}

variable "vm_config" {
  description = "Configuration for each K3s node"
  type = map(object({
    vmid      = number
    cores     = number
    memory    = number
    disk_size = string
    network   = string
    static_ip = string
    gateway   = string
    dns       = string
    net_tag   = number
  }))
}

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
  type = map(string)
}

variable "vm_config" {
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

variable "k3s_token" {
  description = "Token for securing the K3s cluster"
  type        = string
  sensitive   = true
}

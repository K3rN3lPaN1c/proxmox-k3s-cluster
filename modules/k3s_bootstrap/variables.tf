variable "k3s_token" {
  type        = string
  sensitive   = true
}

variable "master_nodes" {
  type = map(string)
}

variable "primary_master" {
  type = string
}

variable "vm_user" {
  type        = string
  description = "Default user for the VMs"
}

variable "ssh_priv_key" {
  type        = string
  description = "SSH private key"
}

variable "registry_url" {
  description = "Custom Docker registry URL to override docker.io"
  type        = string
}

variable "registry_username" {
  description = "Username for the custom registry authentication"
  type        = string
}

variable "registry_password" {
  description = "Password for the custom registry authentication"
  type        = string
  sensitive   = true
}
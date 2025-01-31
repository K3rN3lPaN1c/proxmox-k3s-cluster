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

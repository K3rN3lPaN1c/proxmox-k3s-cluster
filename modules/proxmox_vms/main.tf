terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "=3.0.1-rc6"
    }
  }
  required_version = ">= 0.14"
}

provider "proxmox" {
  pm_api_url         = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure         = true
}

resource "proxmox_vm_qemu" "k3s_cluster" {
  for_each = var.vm_config

  name        = each.key
  target_node = var.vm_nodes[each.key]
  clone       = "debian-12-template"

  cores       = each.value.cores
  memory      = each.value.memory
  sockets     = 1
  cpu_type    = "host"
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  vmid = each.value.vmid

  disks {
    ide {
      ide2 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size    = each.value.disk_size
          cache   = "writeback"
          storage = "local-lvm"
          discard = true
        }
      }
    }
  }

  network {
    id = 0
    model   = "virtio"
    bridge  = each.value.network
    tag     = each.value.net_tag
  }

  serial {
    id   = 0
    type = "socket"
  }

  ipconfig0  = "ip=${each.value.static_ip}/24,gw=${each.value.gateway}"
  nameserver = each.value.dns

  ciuser     = var.vm_user
  cipassword = var.vm_password
  sshkeys    = file(var.ssh_pub_key)

  tags = "k3s-cluster"
}


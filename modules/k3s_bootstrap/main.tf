resource "null_resource" "install_k3s_primary_master" {
  connection {
    type        = "ssh"
    user        = "debian"
    private_key = file("~/.ssh/id_rsa")
    host        = var.primary_master
  }

  provisioner "remote-exec" {
    inline = [
      "sudo curl -sfL https://get.k3s.io | sudo K3S_TOKEN=${var.k3s_token} sh -s - server --cluster-init --node-ip=${var.primary_master} --tls-san=${var.primary_master} --tls-san=${var.master_nodes["pub-k3s-02"]} --tls-san=${var.master_nodes["pub-k3s-03"]} --disable=traefik"
    ]
  }
}

resource "null_resource" "install_k3s_secondary_masters" {
  for_each = { for k, v in var.master_nodes : k => v if v != var.primary_master }
  depends_on = [null_resource.install_k3s_primary_master]

  connection {
    type        = "ssh"
    user        = "debian"
    private_key = file("~/.ssh/id_rsa")
    host        = each.value
  }

  provisioner "remote-exec" {
    inline = [
      "sudo curl -sfL https://get.k3s.io | sudo K3S_TOKEN=${var.k3s_token} sh -s - server --server=https://${var.primary_master}:6443 --node-ip=${each.value} --tls-san=${var.primary_master} --tls-san=${var.master_nodes["pub-k3s-02"]} --tls-san=${var.master_nodes["pub-k3s-03"]} --disable=traefik"
    ]
  }
}

terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}
resource "null_resource" "install_open_iscsi" {
  for_each = var.master_nodes

  connection {
    type        = "ssh"
    user        = var.vm_user
    private_key = file(var.ssh_priv_key)
    host        = each.value
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Installing open-iscsi on ${each.value}...'",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -qq -y",
      "sudo apt install -qq -y open-iscsi",
      "sudo systemctl enable iscsid",
      "sudo systemctl start iscsid",
      "echo 'open-iscsi installed successfully on ${each.value}'"
    ]
  }
}

# Generate registries.yaml file locally
resource "local_file" "registries_yaml" {
  depends_on = [null_resource.install_open_iscsi]
  content = templatefile("${path.module}/registries.yaml.tpl", {
    registry_url      = var.registry_url
    registry_username = var.registry_username
    registry_password = var.registry_password
  })
  filename = "${path.module}/registries.yaml"
}

# Upload registry configuration to K3s master nodes
resource "null_resource" "configure_k3s_registry" {
  depends_on = [local_file.registries_yaml]
  for_each = var.master_nodes

  connection {
    type        = "ssh"
    user        = var.vm_user
    private_key = file(var.ssh_priv_key)
    host        = each.value
  }

  provisioner "file" {
    source      = local_file.registries_yaml.filename
    destination = "/tmp/registries.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Applying custom containerd registry configuration...'",
      "sudo mkdir -p /etc/rancher/k3s",
      "sudo mv /tmp/registries.yaml /etc/rancher/k3s/registries.yaml",
      "sudo chmod 600 /etc/rancher/k3s/registries.yaml",
      "sudo chown root:root /etc/rancher/k3s/registries.yaml"
    ]
  }
}

# Install K3s on Primary Master
resource "null_resource" "install_k3s_primary_master" {
    depends_on = [null_resource.configure_k3s_registry]
  connection {
    type        = "ssh"
    user        = var.vm_user
    private_key = file(var.ssh_priv_key)
    host        = var.primary_master
  }

  provisioner "remote-exec" {
    inline = [
      "sudo curl -sfL https://get.k3s.io | sudo K3S_TOKEN=${var.k3s_token} sh -s - server --cluster-init --node-ip=${var.primary_master} --tls-san=${var.primary_master} --tls-san=${var.master_nodes["pub-k3s-02"]} --tls-san=${var.master_nodes["pub-k3s-03"]} --disable=traefik --flannel-backend=none --disable-network-policy"
    ]
  }
}

resource "null_resource" "install_k3s_secondary_masters" {
  for_each = { for k, v in var.master_nodes : k => v if v != var.primary_master }
  depends_on = [null_resource.install_k3s_primary_master]

  connection {
    type        = "ssh"
    user        = var.vm_user
    private_key = file(var.ssh_priv_key)
    host        = each.value
  }

  provisioner "remote-exec" {
    inline = [
      "sudo curl -sfL https://get.k3s.io | sudo K3S_TOKEN=${var.k3s_token} sh -s - server --server=https://${var.primary_master}:6443 --node-ip=${each.value} --tls-san=${var.primary_master} --tls-san=${var.master_nodes["pub-k3s-02"]} --tls-san=${var.master_nodes["pub-k3s-03"]} --disable=traefik --flannel-backend=none --disable-network-policy"
    ]
  }
}

resource "null_resource" "fetch_kubeconfig" {
  depends_on = [null_resource.install_k3s_secondary_masters]

  connection {
    type        = "ssh"
    user        = var.vm_user
    private_key = file(var.ssh_priv_key)
    host        = var.primary_master
  }

  provisioner "remote-exec" {
    inline = ["sudo chmod 644 /etc/rancher/k3s/k3s.yaml"]
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Fetching kubeconfig from primary master..."

      # Copy kubeconfig from K3s primary master to local machine using SCP with private key
      scp -i ${var.ssh_priv_key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      ${var.vm_user}@${var.primary_master}:/etc/rancher/k3s/k3s.yaml ~/.kube/config

      sed -i "s/127.0.0.1/${var.primary_master}/g" ~/.kube/config
      chmod 600 ~/.kube/config
      kubectl get nodes
    EOT
  }
}

resource "null_resource" "deploy_calico" {
  depends_on = [null_resource.fetch_kubeconfig]

  provisioner "local-exec" {
    command = <<EOT
      echo "Installing Calico Operator..."
      kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/tigera-operator.yaml

      echo "Waiting for Tigera operator to be registered..."
      until kubectl -n tigera-operator wait --for=condition=ready pods --all --timeout=300s 2>/dev/null; do
        echo "Waiting for Tigera operator to be ready..."
        sleep 10
      done

      echo "Applying Calico Configuration..."
      kubectl apply -f ./manifests/calico/calico.yaml

      echo "Waiting for Calico pods to be running..."
      until kubectl -n calico-system wait --for=condition=ready pods --all --timeout=300s 2>/dev/null; do
        echo "Waiting for Calico pods to be ready..."
        sleep 10
      done

      echo "Applying Calico BGP Configuration..."
      kubectl apply -f ./manifests/calico/calico-bgp.yaml

      echo "Calico Deployment Complete!"
    EOT
  }
}

resource "null_resource" "deploy_longhorn" {
    depends_on = [null_resource.deploy_calico]

    provisioner "local-exec" {
        command = <<EOT
            echo "Adding Longhorn Helm repository..."
            helm repo add longhorn https://charts.longhorn.io
            helm repo update
            echo "Installing Longhorn..."
            helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
            echo "Waiting for Longhorn to be ready..."
            until kubectl -n longhorn-system wait --for=condition=ready pods --all --timeout=300s 2>/dev/null; do
              echo "Waiting for Longhorn to be ready..."
              sleep 10
            done

            echo "Longhorn Deployment Complete!"
        EOT
    }
}


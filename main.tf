terraform {
    required_providers {
        local = {
        source = "hashicorp/local"
        version = "~> 2.1"
        }
    }
}


provider "local" { }

    resource "local_file" "k3s_install_script" {
    content = <<-EOT
        #!/bin/bash
        # Install k3s
        curl -sfL https://get.k3s.io | sh -

        sudo systemctl enable k3s
        sudo systemctl start k3s

        sudo systemctl status k3s

        sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
        sudo chown \$USER:\$USER ~/.kube/config

        sudo systemctl restart k3s

        echo "K3s installed and configured successfully!"
    EOT

    filename = "${path.module}/install_k3s.sh"
}

resource "null_resource" "install_k3s" {
    provisioner "local-exec" {
        command = "bash ${local_file.k3s_install_script.filename}"
    }

    depends_on = [local_file.k3s_install_script]
}

output "k3s_install_script_path" {
    value = local_file.k3s_install_script.filename
}

resource "null_resource" "check_k3s_logs" {
    provisioner "local-exec" {
        command = "sudo journalctl -u k3s | tail -n 20"
    }

    depends_on = [null_resource.install_k3s]
}

resource "null_resource" "verify_kubectl" {
    provisioner "local-exec" {
        command = "kubectl get nodes"
    }

    depends_on = [null_resource.install_k3s]
}

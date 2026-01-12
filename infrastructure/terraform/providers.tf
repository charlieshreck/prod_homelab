provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006"
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = true

  ssh {
    agent    = false
    username = "root"
    password = var.proxmox_password
  }
}

provider "talos" {}

provider "infisical" {
  host          = "https://app.infisical.com"
  client_id     = var.infisical_client_id
  client_secret = var.infisical_client_secret
}

provider "helm" {
  kubernetes = {
    config_path = "${path.module}/generated/kubeconfig"
  }
}

provider "kubectl" {
  config_path      = "${path.module}/generated/kubeconfig"
  load_config_file = true
}

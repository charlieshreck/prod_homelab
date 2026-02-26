# Default provider - Ruapehu (10.10.0.10)
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

# Hikurangi (10.10.0.178) - Haute Banque LXC
# Uses password auth (root@pam), not API token
provider "proxmox" {
  alias    = "hikurangi"
  endpoint = "https://10.10.0.178:8006"
  username = "root@pam"
  password = var.proxmox_lxc_password
  insecure = true

  ssh {
    agent    = false
    username = "root"
    password = var.proxmox_lxc_password
  }
}

# Pihanga (10.10.0.20) - Synapse LXC + monitoring cluster
# Uses password auth (root@pam), not API token
provider "proxmox" {
  alias    = "pihanga"
  endpoint = "https://10.10.0.20:8006"
  username = "root@pam"
  password = var.proxmox_lxc_password
  insecure = true

  ssh {
    agent    = false
    username = "root"
    password = var.proxmox_lxc_password
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

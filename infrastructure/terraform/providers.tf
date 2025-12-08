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

# ============================================================================
# Omada Software Controller LXC
# Manages TP-Link TL-SG3428X-M2 and future TP-Link network devices
# ============================================================================

variable "omada_lxc" {
  description = "Omada controller LXC configuration"
  type = object({
    vmid   = number
    name   = string
    ip     = string
    cores  = number
    memory = number
    disk   = number
  })
  default = {
    vmid   = 200
    name   = "omada"
    ip     = "10.10.0.3"
    cores  = 1
    memory = 4096  # 4GB - Omada + MongoDB + Java memory footprint increased to prevent 85%+ usage
    disk   = 10
  }
}

locals {
  omada_mac = "52:54:00:10:10:03"
}

module "omada" {
  source = "./modules/omada-lxc"

  proxmox_node = var.proxmox_node
  vm_id        = var.omada_lxc.vmid
  hostname     = var.omada_lxc.name

  cores  = var.omada_lxc.cores
  memory = var.omada_lxc.memory
  swap   = 512

  disk_size      = var.omada_lxc.disk
  disk_datastore = var.proxmox_storage

  network_bridge = var.network_bridge
  ip_address     = "${var.omada_lxc.ip}/24"
  gateway        = var.prod_gateway
  mac_address    = local.omada_mac
  dns_servers    = var.dns_servers

  root_password   = var.proxmox_password
  ssh_public_keys = var.ssh_public_keys
}

# ============================================================================
# Outputs for Ansible
# ============================================================================

output "omada_management_ip" {
  description = "Omada controller management IP for Ansible"
  value       = module.omada.management_ip
}

output "omada_vm_id" {
  description = "Omada controller VMID in Proxmox"
  value       = module.omada.vm_id
}

# ============================================================================
# Synapse LXC on Pihanga
# Tamar PWA + Claude Code host (this machine)
# Host: Pihanga (10.10.0.20), Bridge: vmbr0, Storage: local-lvm
# ============================================================================

variable "synapse_lxc" {
  description = "Synapse (Tamar PWA + Claude Code) LXC configuration"
  type = object({
    vmid   = number
    name   = string
    ip     = string
    cores  = number
    memory = number
    disk   = number
  })
  default = {
    vmid   = 100
    name   = "synapse"
    ip     = "10.10.0.22"
    cores  = 4
    memory = 4096
    disk   = 30
  }
}

module "synapse_lxc" {
  source = "./modules/lxc-node"
  providers = {
    proxmox = proxmox.pihanga
  }

  proxmox_node = "Pihanga" # Case-sensitive!
  vm_id        = var.synapse_lxc.vmid
  hostname     = var.synapse_lxc.name
  description  = "Tamar PWA + Claude Code host"

  cores  = var.synapse_lxc.cores
  memory = var.synapse_lxc.memory
  swap   = 1024

  disk_size      = var.synapse_lxc.disk
  disk_datastore = "local-lvm" # Pihanga uses local-lvm

  network_bridge = "vmbr0" # Pihanga's prod network bridge
  ip_address     = "${var.synapse_lxc.ip}/24"
  gateway        = var.prod_gateway
  mac_address    = "52:54:00:10:00:22"
  dns_servers    = var.dns_servers

  root_password   = var.proxmox_password
  ssh_public_keys = var.ssh_public_keys

  tags = ["tamar", "claude-code", "lxc"]
}

# ============================================================================
# Outputs
# ============================================================================

output "synapse_management_ip" {
  description = "Synapse LXC management IP"
  value       = module.synapse_lxc.management_ip
}

output "synapse_vm_id" {
  description = "Synapse LXC VMID in Proxmox"
  value       = module.synapse_lxc.vm_id
}

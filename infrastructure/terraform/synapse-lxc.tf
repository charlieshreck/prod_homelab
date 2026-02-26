# ============================================================================
# Synapse LXC on Hikurangi
# Tamar PWA + Claude Code host (this machine)
# Host: Hikurangi (10.10.0.178), Bridge: vmbr1, Storage: Aoraki ZFS
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
    cores  = 2
    memory = 6144
    disk   = 50
  }
}

module "synapse_lxc" {
  source = "./modules/lxc-node"
  providers = {
    proxmox = proxmox.hikurangi
  }

  proxmox_node = "Hikurangi" # Case-sensitive!
  vm_id        = var.synapse_lxc.vmid
  hostname     = var.synapse_lxc.name
  description  = "Tamar PWA + Claude Code host"

  cores  = var.synapse_lxc.cores
  memory = var.synapse_lxc.memory
  swap   = 0

  disk_size      = var.synapse_lxc.disk
  disk_datastore = "Aoraki" # Hikurangi uses Aoraki ZFS pool

  network_bridge = "vmbr0" # Primary NIC on prod network (also has vmbr1 for AI network)
  ip_address     = "${var.synapse_lxc.ip}/24"
  gateway        = var.prod_gateway
  mac_address    = "BC:24:11:8B:3C:13"
  dns_servers    = var.dns_servers

  root_password   = var.proxmox_lxc_password
  ssh_public_keys = var.ssh_public_keys

  unprivileged = false # Existing privileged container

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

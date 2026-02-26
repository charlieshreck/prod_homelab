# ============================================================================
# Haute Banque (Investmentology) LXC on Hikurangi
# AI investment advisory - Claude CLI + Gemini CLI agents
# Host: Hikurangi (10.10.0.178), Bridge: vmbr1, Storage: Aoraki ZFS
# ============================================================================

variable "hb_lxc" {
  description = "Haute Banque (Investmentology) LXC configuration"
  type = object({
    vmid   = number
    name   = string
    ip     = string
    cores  = number
    memory = number
    disk   = number
  })
  default = {
    vmid   = 101
    name   = "haute-banque"
    ip     = "10.10.0.101"
    cores  = 2
    memory = 4096
    disk   = 30
  }
}

module "hb_lxc" {
  source = "./modules/lxc-node"
  providers = {
    proxmox = proxmox.hikurangi
  }

  proxmox_node = "Hikurangi" # Case-sensitive!
  vm_id        = var.hb_lxc.vmid
  hostname     = var.hb_lxc.name
  description  = "Investmentology AI analysis worker - Claude CLI + Gemini CLI agents"

  cores  = var.hb_lxc.cores
  memory = var.hb_lxc.memory
  swap   = 512

  disk_size      = var.hb_lxc.disk
  disk_datastore = "Aoraki" # Hikurangi uses Aoraki ZFS pool

  network_bridge = "vmbr1" # Hikurangi's prod network bridge
  ip_address     = "${var.hb_lxc.ip}/24"
  gateway        = var.prod_gateway
  mac_address    = "52:54:00:10:01:01"
  dns_servers    = var.dns_servers

  root_password   = var.proxmox_password
  ssh_public_keys = var.ssh_public_keys

  tags = ["investmentology", "ai-worker", "lxc"]
}

# ============================================================================
# Outputs
# ============================================================================

output "hb_management_ip" {
  description = "Haute Banque LXC management IP"
  value       = module.hb_lxc.management_ip
}

output "hb_vm_id" {
  description = "Haute Banque LXC VMID in Proxmox"
  value       = module.hb_lxc.vm_id
}

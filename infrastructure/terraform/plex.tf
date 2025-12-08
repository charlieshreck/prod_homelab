# ============================================================================
# Plex Media Server VM with Nvidia GPU Passthrough
# ============================================================================

module "plex" {
  source = "./modules/plex-vm-nvidia"

  vm_name      = var.plex_vm.name
  vm_id        = var.plex_vm.vmid
  proxmox_node = var.proxmox_node

  cores  = var.plex_vm.cores
  memory = var.plex_vm.memory

  mac_address   = local.plex_config.mac_address
  management_ip = var.plex_vm.ip
  truenas_ip    = var.plex_vm.truenas_ip
  gateway       = var.prod_gateway

  network_bridge = var.network_bridge
  truenas_bridge = var.truenas_bridge

  disk_datastore = var.proxmox_storage
  disk_size      = var.plex_vm.disk

  gpu_pci_id = var.plex_vm.gpu_pci_id

  ssh_user       = "root"
  ssh_password   = var.proxmox_password  # Using same password as Proxmox
  ssh_public_keys = var.ssh_public_keys
}

# ============================================================================
# Outputs for Ansible
# ============================================================================

output "plex_management_ip" {
  description = "Plex VM management IP for Ansible"
  value       = module.plex.management_ip
}

output "plex_truenas_ip" {
  description = "Plex VM TrueNAS NFS network IP"
  value       = module.plex.truenas_ip
}

output "plex_vm_id" {
  description = "Plex VM ID in Proxmox"
  value       = module.plex.vm_id
}

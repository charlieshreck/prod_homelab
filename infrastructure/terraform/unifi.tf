# ============================================================================
# UniFi OS Server VM with Podman
# ============================================================================

module "unifi" {
  source = "./modules/unifi-vm"

  vm_name      = var.unifi_vm.name
  vm_id        = var.unifi_vm.vmid
  proxmox_node = var.proxmox_node

  cores  = var.unifi_vm.cores
  memory = var.unifi_vm.memory

  mac_address   = local.unifi_config.mac_address
  management_ip = var.unifi_vm.ip
  gateway       = var.prod_gateway

  network_bridge = var.network_bridge
  disk_datastore = var.proxmox_storage
  disk_size      = var.unifi_vm.disk

  ssh_user        = "root"
  ssh_password    = var.proxmox_password
  ssh_public_keys = var.ssh_public_keys

  # Skip cloud-init for already-provisioned VM
  skip_cloud_init = true
}

# ============================================================================
# Outputs for Ansible
# ============================================================================

output "unifi_management_ip" {
  description = "UniFi VM management IP for Ansible"
  value       = module.unifi.management_ip
}

output "unifi_vm_id" {
  description = "UniFi VM ID in Proxmox"
  value       = module.unifi.vm_id
}

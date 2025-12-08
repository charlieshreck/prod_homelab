output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.talos_worker.vm_id
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.talos_worker.name
}

output "management_ip" {
  description = "Management network IP (vmbr0/eth0)"
  value       = var.mac_address  # Note: Actual IP is configured in Talos config
}

output "mac_address" {
  description = "MAC address for management interface"
  value       = var.mac_address
}

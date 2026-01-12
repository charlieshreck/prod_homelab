output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.unifi.vm_id
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.unifi.name
}

output "management_ip" {
  description = "Management network IP (vmbr0)"
  value       = var.management_ip
}

output "mac_address" {
  description = "MAC address"
  value       = var.mac_address
}

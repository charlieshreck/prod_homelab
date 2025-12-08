output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.plex.vm_id
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.plex.name
}

output "management_ip" {
  description = "Management network IP (vmbr0)"
  value       = var.management_ip
}

output "truenas_ip" {
  description = "TrueNAS NFS network IP (vmbr3)"
  value       = var.truenas_ip
}

output "gpu_pci_id" {
  description = "GPU PCI ID"
  value       = var.gpu_pci_id
}

output "mac_address" {
  description = "MAC address"
  value       = var.mac_address
}

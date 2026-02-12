output "vm_id" {
  description = "Container VMID"
  value       = proxmox_virtual_environment_container.omada.vm_id
}

output "management_ip" {
  description = "Container management IP"
  value       = split("/", var.ip_address)[0]
}

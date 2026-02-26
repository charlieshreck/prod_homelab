# ============================================================================
# Generic LXC Container Module - Outputs
# ============================================================================

output "vm_id" {
  description = "Container VMID"
  value       = proxmox_virtual_environment_container.lxc.vm_id
}

output "management_ip" {
  description = "Container management IP (without CIDR suffix)"
  value       = split("/", var.ip_address)[0]
}

output "hostname" {
  description = "Container hostname"
  value       = var.hostname
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_id" {
  description = "VM ID in Proxmox"
  type        = number
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 12288
}

variable "mac_address" {
  description = "MAC address for primary network interface (vmbr0)"
  type        = string
}

variable "network_bridge" {
  description = "Management network bridge (vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "truenas_bridge" {
  description = "TrueNAS NFS network bridge (vmbr3)"
  type        = string
  default     = "vmbr3"
}

variable "storage_bridge" {
  description = "Mayastor storage replication network bridge (vmbr4)"
  type        = string
  default     = "vmbr4"
}

variable "boot_disk_datastore" {
  description = "Datastore for boot disk (Ranginui ZFS pool)"
  type        = string
  default     = "Ranginui"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "mayastor_disk_size" {
  description = "Mayastor disk size in GB (zvol pre-created with Proxmox naming)"
  type        = number
  default     = 1200
}

variable "talos_iso_file_id" {
  description = "Proxmox file ID for Talos ISO image"
  type        = string
}

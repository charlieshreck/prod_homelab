variable "vm_name" {
  description = "Name of the Plex VM"
  type        = string
  default     = "plex"
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
  default     = 8192
}

variable "mac_address" {
  description = "MAC address for primary network interface"
  type        = string
}

variable "management_ip" {
  description = "Management network IP address (without CIDR)"
  type        = string
}

variable "truenas_ip" {
  description = "TrueNAS NFS network IP address"
  type        = string
}

variable "gateway" {
  description = "Default gateway"
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

variable "disk_datastore" {
  description = "Datastore for disk (Ranginui ZFS pool)"
  type        = string
  default     = "Ranginui"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 100
}

variable "gpu_pci_id" {
  description = "PCI ID for GPU passthrough (e.g., 0000:0d:00)"
  type        = string
}

variable "ssh_user" {
  description = "SSH username for cloud-init"
  type        = string
  default     = "root"
}

variable "ssh_password" {
  description = "SSH password for cloud-init"
  type        = string
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "SSH public keys for VM access"
  type        = list(string)
  default     = []
}

variable "skip_cloud_init" {
  description = "Skip cloud-init file creation for already-provisioned VMs"
  type        = bool
  default     = false
}

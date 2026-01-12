variable "vm_name" {
  description = "Name of the UniFi VM"
  type        = string
  default     = "unifi"
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
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "mac_address" {
  description = "MAC address for primary network interface"
  type        = string
}

variable "management_ip" {
  description = "Management network IP address (without CIDR)"
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

variable "disk_datastore" {
  description = "Datastore for disk (Ranginui ZFS pool)"
  type        = string
  default     = "Ranginui"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 50
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

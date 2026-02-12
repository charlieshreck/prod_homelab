variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "vm_id" {
  description = "Container VMID"
  type        = number
}

variable "hostname" {
  description = "Container hostname"
  type        = string
}

variable "cores" {
  description = "CPU cores"
  type        = number
  default     = 1
}

variable "memory" {
  description = "RAM in MB"
  type        = number
  default     = 1024
}

variable "swap" {
  description = "Swap in MB"
  type        = number
  default     = 512
}

variable "disk_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 10
}

variable "disk_datastore" {
  description = "Proxmox storage pool for disk"
  type        = string
}

variable "network_bridge" {
  description = "Network bridge for LXC"
  type        = string
}

variable "ip_address" {
  description = "Static IP address (CIDR notation, e.g. 10.10.0.3/24)"
  type        = string
}

variable "gateway" {
  description = "Default gateway"
  type        = string
}

variable "mac_address" {
  description = "MAC address for network interface"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["10.10.0.1", "9.9.9.9"]
}

variable "ssh_public_keys" {
  description = "SSH public keys for root access"
  type        = list(string)
  default     = []
}

variable "root_password" {
  description = "Root password for the container"
  type        = string
  sensitive   = true
}

variable "template_file" {
  description = "Container template filename"
  type        = string
  default     = "debian-12-standard_12.12-1_amd64.tar.zst"
}

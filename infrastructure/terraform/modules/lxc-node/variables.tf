# ============================================================================
# Generic LXC Container Module - Variables
# ============================================================================

variable "proxmox_node" {
  description = "Proxmox node name (case-sensitive)"
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

variable "description" {
  description = "Container description"
  type        = string
  default     = ""
}

# Resource allocation
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

# Disk configuration
variable "disk_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 10
}

variable "disk_datastore" {
  description = "Proxmox storage pool for disk"
  type        = string
}

# Network configuration
variable "network_bridge" {
  description = "Network bridge for LXC"
  type        = string
}

variable "ip_address" {
  description = "Static IP address (CIDR notation, e.g. 10.10.0.22/24)"
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

# Authentication
variable "root_password" {
  description = "Root password for the container"
  type        = string
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "SSH public keys for root access"
  type        = list(string)
  default     = []
}

# Template
variable "template_file" {
  description = "Container template filename"
  type        = string
  default     = "debian-13-standard_13.1-2_amd64.tar.zst"
}

# Container features
variable "unprivileged" {
  description = "Run as unprivileged container"
  type        = bool
  default     = true
}

variable "nesting" {
  description = "Enable nesting (for Docker-in-LXC, systemd, etc.)"
  type        = bool
  default     = true
}

variable "keyctl" {
  description = "Enable keyctl (required for some systemd features)"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags for container categorization"
  type        = list(string)
  default     = []
}

# Optional mount points
variable "mount_points" {
  description = "Additional mount points (e.g. NFS volumes)"
  type = list(object({
    volume = string
    path   = string
    size   = optional(string, "")
  }))
  default = []
}

# Proxmox Connection
variable "proxmox_host" {
  description = "Proxmox host address"
  type        = string
  default     = "10.10.0.10"
}

variable "proxmox_user" {
  description = "Proxmox API user"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "Ruapehu"
}

# Network Configuration
variable "network_bridge" {
  description = "Management network bridge"
  type        = string
  default     = "vmbr0"
}

variable "truenas_bridge" {
  description = "TrueNAS NFS network bridge (40GbE)"
  type        = string
  default     = "vmbr3"
}

variable "storage_bridge" {
  description = "Mayastor replication network bridge (40GbE)"
  type        = string
  default     = "vmbr4"
}

variable "prod_gateway" {
  description = "Production network gateway"
  type        = string
  default     = "10.10.0.1"
}

variable "dns_servers" {
  description = "DNS servers (local DNS stack for internal resolution, public fallback)"
  type        = list(string)
  default     = ["10.10.0.1", "9.9.9.9"]
}

# Cluster Configuration
variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "homelab-prod"
}

variable "talos_version" {
  description = "Talos Linux version"
  type        = string
  default     = "v1.11.3"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.34.1"
}

# Storage Configuration
variable "proxmox_storage" {
  description = "Proxmox storage pool for boot disks (Ranginui ZFS pool)"
  type        = string
  default     = "Ranginui"
}

variable "proxmox_mayastor_storage" {
  description = "Proxmox storage pool for Mayastor disks (Taranaki ZFS pool)"
  type        = string
  default     = "Taranaki"
}

variable "proxmox_iso_storage" {
  description = "Proxmox storage for ISO images"
  type        = string
  default     = "local"
}

# VM IDs
variable "vm_id_start" {
  description = "Starting VM ID for cluster VMs"
  type        = number
  default     = 400
}

# Control Plane Configuration
variable "control_plane" {
  description = "Control plane VM configuration"
  type = object({
    name   = string
    ip     = string
    cores  = number
    memory = number
    disk   = number
  })
  default = {
    name   = "talos-cp-01"
    ip     = "10.10.0.40"
    cores  = 4
    memory = 5120  # 5GB - increased to reduce memory pressure (was 4GB at 85% utilization)
    disk   = 50
  }
}

# Worker Configuration
variable "workers" {
  description = "Worker VM configurations (triple-NIC: vmbr0, vmbr3, vmbr4)"
  type = map(object({
    name          = string
    ip            = string
    truenas_ip    = string
    storage_ip    = string
    cores         = number
    memory        = number
    disk          = number
    mayastor_disk = number
  }))
  default = {
    "worker-01" = {
      name          = "talos-worker-01"
      ip            = "10.10.0.41"
      truenas_ip    = "10.40.0.41"
      storage_ip    = "10.50.0.41"
      cores         = 6  # Increased from 4: Mayastor SPDK busy-polls 2 vCPUs constantly (~50% floor); 4 vCPUs left no headroom for Renovate/workloads
      memory        = 9216  # 9GB (reduced from 12GB to reduce host memory pressure)
      disk          = 50
      mayastor_disk = 1000  # Reduced from 1100GB to prevent Taranaki pool saturation
    }
    "worker-02" = {
      name          = "talos-worker-02"
      ip            = "10.10.0.42"
      truenas_ip    = "10.40.0.42"
      storage_ip    = "10.50.0.42"
      cores         = 6  # Increased from 4: Mayastor SPDK busy-polls 2 vCPUs constantly (~50% floor); 4 vCPUs left no headroom for Renovate/workloads
      memory        = 9216  # 9GB (reduced from 12GB to reduce host memory pressure)
      disk          = 50
      mayastor_disk = 1000  # Reduced from 1100GB to prevent Taranaki pool saturation
    }
    "worker-03" = {
      name          = "talos-worker-03"
      ip            = "10.10.0.43"
      truenas_ip    = "10.40.0.43"
      storage_ip    = "10.50.0.43"
      cores         = 6  # Increased from 4: Mayastor SPDK busy-polls 2 vCPUs constantly (~50% floor); 4 vCPUs left no headroom for Renovate/workloads
      memory        = 9216  # 9GB (reduced from 12GB to reduce host memory pressure)
      disk          = 50
      mayastor_disk = 1000  # Reduced from 1100GB to prevent Taranaki pool saturation
    }
  }
}

# Plex VM Configuration
variable "plex_vm" {
  description = "Plex VM configuration with GPU passthrough"
  type = object({
    vmid       = number
    name       = string
    ip         = string
    truenas_ip = string
    cores      = number
    memory     = number
    disk       = number
    gpu_pci_id = string
  })
  default = {
    vmid       = 450
    name       = "plex"
    ip         = "10.10.0.50"
    truenas_ip = "10.40.0.50"
    cores      = 4
    memory     = 7168  # 7GB (increased from 6GB - currently oversubscribed at 6.5GB)
    disk       = 100
    gpu_pci_id = "0000:0d:00"  # Nvidia P4000
  }
}

# UniFi OS Server VM Configuration
variable "unifi_vm" {
  description = "UniFi OS Server VM configuration with Podman"
  type = object({
    vmid   = number
    name   = string
    ip     = string
    cores  = number
    memory = number
    disk   = number
  })
  default = {
    vmid   = 451
    name   = "unifi"
    ip     = "10.10.0.51"
    cores  = 2
    memory = 3072  # 3GB - UniFi stack actual RSS ~1.2GB + OS/cache needs ~1.9GB total, balloon disabled
    disk   = 50
  }
}

# GitOps Configuration
variable "gitops_repo_url" {
  description = "GitOps repository URL"
  type        = string
  default     = "https://github.com/charlieshreck/prod_homelab.git"
}

variable "gitops_repo_branch" {
  description = "GitOps repository branch"
  type        = string
  default     = "main"
}

# Cilium LoadBalancer Configuration
variable "cilium_lb_ip_pool" {
  description = "IP pool for Cilium LoadBalancer"
  type = list(object({
    start = string
    stop  = string
  }))
  default = [
    {
      start = "10.10.0.90"
      stop  = "10.10.0.99"
    }
  ]
}

# Cloudflare Configuration
variable "cloudflare_email" {
  description = "Cloudflare account email"
  type        = string
  default     = "charlieshreck@gmail.com"
}

variable "cloudflare_domain" {
  description = "Primary domain managed by Cloudflare"
  type        = string
  default     = "kernow.io"
}

# Infisical Configuration
variable "infisical_project_id" {
  description = "Infisical project ID (UUID)"
  type        = string
  default     = "9383e039-68ca-4bab-bc3c-aa06fdb82627"
}

variable "infisical_project_slug" {
  description = "Infisical project slug"
  type        = string
  default     = "prod-homelab-y-nij"
}

variable "infisical_env_slug" {
  description = "Infisical environment slug"
  type        = string
  default     = "prod"
}

variable "infisical_client_id" {
  description = "Infisical Universal Auth client ID"
  type        = string
  sensitive   = true
}

variable "infisical_client_secret" {
  description = "Infisical Universal Auth client secret"
  type        = string
  sensitive   = true
}

# Docker Hub Configuration
variable "dockerhub_username" {
  description = "Docker Hub username"
  type        = string
  default     = "mrlong67"
}

variable "dockerhub_password" {
  description = "Docker Hub password/token"
  type        = string
  sensitive   = true
}

# SSH Keys
variable "ssh_public_keys" {
  description = "SSH public keys for VM access"
  type        = list(string)
  default     = []
}

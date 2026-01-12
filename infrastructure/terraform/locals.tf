locals {
  # MAC address generation for static DHCP assignment
  # Pattern: 52:54:00:10:10:XX where XX is last octet of IP
  control_plane_mac = "52:54:00:10:10:40"

  worker_macs = {
    "worker-01" = "52:54:00:10:10:41"
    "worker-02" = "52:54:00:10:10:42"
    "worker-03" = "52:54:00:10:10:43"
  }

  plex_mac = "52:54:00:10:10:50"

  unifi_mac = "52:54:00:10:10:51"

  # Worker IP allocations (triple-NIC)
  # eth0 (vmbr0): Management network (10.10.0.x)
  # eth1 (vmbr3): TrueNAS NFS network (10.40.0.x)
  # eth2 (vmbr4): Mayastor replication network (10.50.0.x)
  workers_config = {
    for key, worker in var.workers : key => merge(worker, {
      mac_address = local.worker_macs[key]
      vm_id       = var.vm_id_start + index(keys(var.workers), key) + 1
      # Proxmox zvol naming: vm-<vmid>-disk-1 (SCSI1 disk for Mayastor)
      mayastor_zvol = "/dev/zvol/${var.proxmox_mayastor_storage}/vm-${var.vm_id_start + index(keys(var.workers), key) + 1}-disk-1"
    })
  }

  # Control plane configuration
  control_plane_config = merge(var.control_plane, {
    mac_address = local.control_plane_mac
    vm_id       = var.vm_id_start
  })

  # Plex VM configuration
  plex_config = merge(var.plex_vm, {
    mac_address = local.plex_mac
  })

  # UniFi VM configuration
  unifi_config = merge(var.unifi_vm, {
    mac_address = local.unifi_mac
  })

  # Cluster endpoint (control plane IP)
  cluster_endpoint = "https://${var.control_plane.ip}:6443"

  # Mayastor storage node specifications
  mayastor_nodes = {
    for key, worker in local.workers_config : key => {
      node_name     = worker.name
      storage_ip    = worker.storage_ip  # vmbr4 network IP
      disk_device   = "/dev/sdb"         # SCSI1 disk (Mayastor volume)
      pool_name     = "${worker.name}-pool"
      disk_size_gb  = worker.mayastor_disk
    }
  }

  # Network configuration summary
  networks = {
    management = {
      bridge  = var.network_bridge
      network = "10.10.0.0/24"
      gateway = var.prod_gateway
    }
    truenas = {
      bridge  = var.truenas_bridge
      network = "10.40.0.0/24"
      mtu     = 9000
    }
    mayastor = {
      bridge  = var.storage_bridge
      network = "10.50.0.0/24"
      mtu     = 1500
    }
  }

  # GitOps repository configuration
  gitops = {
    repo_url = var.gitops_repo_url
    branch   = var.gitops_repo_branch
    path     = "kubernetes"
  }
}

# ============================================================================
# Generic LXC Container Module
# ============================================================================
# Reusable module for provisioning LXC containers on any Proxmox node.
# Supports aliased providers for multi-host deployments.
#
# Template must be pre-downloaded on the target node:
#   pveam download local <template_file>
# ============================================================================

terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_container" "lxc" {
  description = var.description
  node_name   = var.proxmox_node
  vm_id       = var.vm_id
  tags        = sort(var.tags)

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
      domain  = "kernow.local"
    }

    user_account {
      password = var.root_password
      keys     = var.ssh_public_keys
    }
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  disk {
    datastore_id = var.disk_datastore
    size         = var.disk_size
  }

  network_interface {
    name        = "eth0"
    bridge      = var.network_bridge
    mac_address = var.mac_address
  }

  operating_system {
    template_file_id = "local:vztmpl/${var.template_file}"
    type             = "debian"
  }

  features {
    nesting = var.nesting
    keyctl  = var.keyctl
  }

  dynamic "mount_point" {
    for_each = var.mount_points
    content {
      volume = mount_point.value.volume
      path   = mount_point.value.path
      size   = mount_point.value.size
    }
  }

  start_on_boot = true
  started       = true
  unprivileged  = var.unprivileged

  lifecycle {
    ignore_changes = [
      initialization,
      operating_system,
      network_interface,
      unprivileged,
    ]
  }
}

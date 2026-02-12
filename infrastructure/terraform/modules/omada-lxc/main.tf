terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

# Use pre-existing template on Proxmox node
# If not present, run: pveam download local <template_file>

resource "proxmox_virtual_environment_container" "omada" {
  description = "Omada Software Controller for TP-Link managed switch"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id

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
    nesting = true
    keyctl  = true
  }

  start_on_boot = true
  started       = true
  unprivileged  = true

  lifecycle {
    ignore_changes = [
      initialization,
    ]
  }
}

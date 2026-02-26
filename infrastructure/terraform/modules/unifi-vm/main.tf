terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

# Download latest Debian 13 (Trixie) cloud image
resource "proxmox_virtual_environment_download_file" "debian_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node

  # Debian 13 (Trixie) stable cloud image - qcow2 format
  url = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"

  file_name           = "debian-13-generic-amd64.img"
  overwrite           = false
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "unifi" {
  name        = var.vm_name
  description = "UniFi OS Server with Podman"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id

  # CPU Configuration
  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
    floating  = 0 # Disable balloon - actual usage is ~1.9GB (Node.js 642MB + Java 296MB + MongoDB + OS), ballooning causes severe swap thrashing
  }

  # Standard BIOS (no GPU passthrough needed)
  bios    = "seabios"
  machine = "q35"

  # Network Device: vmbr0 (Management - 10.10.0.51)
  network_device {
    bridge      = var.network_bridge
    mac_address = var.mac_address
    model       = "virtio"
  }

  # Main Disk - Import Debian cloud image and resize
  disk {
    datastore_id = var.disk_datastore
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = "raw"
    ssd          = true
    discard      = "on"
    file_id      = proxmox_virtual_environment_download_file.debian_cloud_image.id
  }

  # Initialization (cloud-init for Debian)
  initialization {
    datastore_id = "local"

    ip_config {
      ipv4 {
        address = "${var.management_ip}/24"
        gateway = var.gateway
      }
    }

    user_data_file_id = var.skip_cloud_init ? null : proxmox_virtual_environment_file.cloud_init[0].id
  }

  # Operating system
  operating_system {
    type = "l26" # Linux 2.6+ kernel
  }

  # Agent
  agent {
    enabled = true
  }

  # Startup/shutdown settings
  on_boot = true
  started = true

  lifecycle {
    ignore_changes = [
      # Ignore changes to initialization after first boot
      initialization,
      # Ignore disk file_id changes - the cloud image was only used for initial creation
      disk[0].file_id,
    ]
  }
}

# Cloud-init configuration (skipped for already-provisioned VMs)
resource "proxmox_virtual_environment_file" "cloud_init" {
  count = var.skip_cloud_init ? 0 : 1

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      hostname = var.vm_name
      username = var.ssh_user
      password = var.ssh_password
      ssh_keys = var.ssh_public_keys
    })
    file_name = "${var.vm_name}-cloud-init.yaml"
  }
}

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

  # Debian 13 (Trixie) stable cloud image - automatically gets latest
  url = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"

  file_name               = "debian-13-generic-amd64.qcow2"
  overwrite               = false
  overwrite_unmanaged     = true
  checksum                = null
  checksum_algorithm      = null
}

resource "proxmox_virtual_environment_vm" "plex" {
  name        = var.vm_name
  description = "Plex Media Server with Nvidia P4000 GPU passthrough"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id

  # CPU Configuration
  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  # BIOS settings
  bios = "ovmf"

  # EFI disk
  efi_disk {
    datastore_id = var.disk_datastore
    file_format  = "raw"
    type         = "4m"
  }

  # Network Device 1: vmbr0 (Management - 10.10.0.50)
  network_device {
    bridge      = var.network_bridge
    mac_address = var.mac_address
    model       = "virtio"
  }

  # Network Device 2: vmbr3 (TrueNAS NFS - 10.40.0.50, MTU 9000)
  network_device {
    bridge = var.truenas_bridge
    model  = "virtio"
    mtu    = 9000
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

  # GPU Passthrough - Nvidia P4000
  hostpci {
    device  = "hostpci0"
    id      = var.gpu_pci_id
    pcie    = true
    rombar  = true
    xvga    = false
  }

  # Initialization (cloud-init for Debian/Ubuntu)
  initialization {
    datastore_id = var.disk_datastore

    ip_config {
      ipv4 {
        address = "${var.management_ip}/24"
        gateway = var.gateway
      }
    }

    # Second NIC for TrueNAS network
    ip_config {
      ipv4 {
        address = "${var.truenas_ip}/24"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }

  # Operating system
  operating_system {
    type = "l26"  # Linux 2.6+ kernel
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
    ]
  }
}

# Cloud-init configuration
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.disk_datastore
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

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  name        = var.vm_name
  description = "Talos Linux worker node with triple-NIC (vmbr0/vmbr3/vmbr4)"
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
    datastore_id = var.boot_disk_datastore
    file_format  = "raw"
    type         = "4m"
  }

  # Network Device 1: vmbr0 (Management - 10.10.0.x)
  network_device {
    bridge      = var.network_bridge
    mac_address = var.mac_address
    model       = "virtio"
  }

  # Network Device 2: vmbr3 (TrueNAS NFS - 10.40.0.x, MTU 9000)
  network_device {
    bridge = var.truenas_bridge
    model  = "virtio"
    mtu    = 9000
  }

  # Network Device 3: vmbr4 (Mayastor replication - 10.50.0.x)
  network_device {
    bridge = var.storage_bridge
    model  = "virtio"
  }

  # Boot Disk (SCSI0) - on Ranginui ZFS pool
  disk {
    datastore_id = var.boot_disk_datastore
    interface    = "scsi0"
    size         = var.boot_disk_size
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  # Mayastor Disk (SCSI1) - from Taranaki LVM VG
  # This will be a pre-created LVM logical volume
  disk {
    datastore_id = "local-lvm"
    file_id      = var.mayastor_lv_path
    interface    = "scsi1"
    size         = var.mayastor_disk_size
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  # CD-ROM for Talos ISO boot
  cdrom {
    enabled   = true
    file_id   = var.talos_iso_file_id
    interface = "ide2"
  }

  # Serial console
  serial_device {}

  # Startup/shutdown settings
  on_boot = true
  started = true

  # Operating system
  operating_system {
    type = "l26"  # Linux 2.6+ kernel
  }

  # Agent
  agent {
    enabled = false  # Talos doesn't use qemu-guest-agent
  }

  # Machine config will be applied via Talos provider after VM creation
  lifecycle {
    ignore_changes = [
      # Ignore changes to these attributes after initial creation
      cdrom,
      disk,
    ]
  }
}

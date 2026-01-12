# ============================================================================
# UniFi OS Server VM - Standalone Terraform Configuration
# ============================================================================
# This is a standalone config to deploy just the UniFi VM without
# dependencies on the Talos cluster configuration.
# ============================================================================

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006"
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = true

  ssh {
    agent    = false
    username = "root"
    password = var.proxmox_password
  }
}

# Variables
variable "proxmox_host" {
  default = "10.10.0.10"
}

variable "proxmox_user" {
  default = "root@pam"
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  default = "Ruapehu"
}

variable "vm_id" {
  default = 451
}

variable "vm_name" {
  default = "unifi"
}

variable "vm_ip" {
  default = "10.10.0.51"
}

variable "gateway" {
  default = "10.10.0.1"
}

variable "cores" {
  default = 2
}

variable "memory" {
  default = 4096
}

variable "disk_size" {
  default = 50
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

# Download Debian 13 cloud image
resource "proxmox_virtual_environment_download_file" "debian_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node

  url       = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  file_name = "debian-13-generic-amd64.img"

  overwrite               = false
  overwrite_unmanaged     = true
}

# Cloud-init configuration
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data = <<-EOF
      #cloud-config
      hostname: ${var.vm_name}
      manage_etc_hosts: true

      ssh_pwauth: true
      disable_root: false
      chpasswd:
        expire: false

      users:
        - name: root
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          lock_passwd: false
          plain_text_passwd: ${var.ssh_password}

      package_update: true
      package_upgrade: true

      packages:
        - qemu-guest-agent
        - curl
        - wget
        - vim
        - net-tools

      runcmd:
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
        - echo "Cloud-init setup complete" > /var/log/cloud-init-done.log

      power_state:
        mode: reboot
        condition: True
    EOF
    file_name = "${var.vm_name}-cloud-init.yaml"
  }
}

# UniFi VM
resource "proxmox_virtual_environment_vm" "unifi" {
  name        = var.vm_name
  description = "UniFi OS Server with Podman"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  bios    = "seabios"
  machine = "q35"

  network_device {
    bridge      = "vmbr0"
    mac_address = "52:54:00:10:10:51"
    model       = "virtio"
  }

  disk {
    datastore_id = "Ranginui"
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = "raw"
    ssd          = true
    discard      = "on"
    file_id      = proxmox_virtual_environment_download_file.debian_cloud_image.id
  }

  initialization {
    datastore_id = "local"

    ip_config {
      ipv4 {
        address = "${var.vm_ip}/24"
        gateway = var.gateway
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  on_boot = true
  started = true

  lifecycle {
    ignore_changes = [initialization]
  }
}

# Outputs
output "vm_ip" {
  value = var.vm_ip
}

output "vm_id" {
  value = proxmox_virtual_environment_vm.unifi.vm_id
}

output "ssh_command" {
  value = "ssh root@${var.vm_ip}"
}

output "unifi_url" {
  value = "https://${var.vm_ip}:11443"
}

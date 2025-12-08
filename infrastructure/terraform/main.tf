# ============================================================================
# Talos Kubernetes Cluster Deployment
# ============================================================================
# This configuration deploys:
# - 1 Control Plane node (single NIC on vmbr0)
# - 3 Worker nodes (triple NIC on vmbr0/vmbr3/vmbr4)
# - Talos Linux bootstrap
# ============================================================================

# Download and upload Talos ISO to Proxmox
resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  content_type = "iso"
  datastore_id = var.proxmox_iso_storage
  node_name    = var.proxmox_node
  url          = "https://factory.talos.dev/image/${var.talos_version}/nocloud-amd64.iso"

  file_name               = local.talos_iso
  overwrite               = false
  overwrite_unmanaged     = true
  checksum                = null
  checksum_algorithm      = null
}

# ============================================================================
# Control Plane VM
# ============================================================================
resource "proxmox_virtual_environment_vm" "control_plane" {
  name        = var.control_plane.name
  description = "Talos Linux control plane node"
  node_name   = var.proxmox_node
  vm_id       = local.control_plane_config.vm_id

  cpu {
    cores = var.control_plane.cores
    type  = "host"
  }

  memory {
    dedicated = var.control_plane.memory
  }

  bios = "ovmf"

  efi_disk {
    datastore_id = var.proxmox_storage
    file_format  = "raw"
    type         = "4m"
  }

  # Single NIC on vmbr0 (management network)
  network_device {
    bridge      = var.network_bridge
    mac_address = local.control_plane_config.mac_address
    model       = "virtio"
  }

  # Boot disk
  disk {
    datastore_id = var.proxmox_storage
    interface    = "scsi0"
    size         = var.control_plane.disk
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  # Talos ISO
  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    interface = "ide2"
  }

  serial_device {}

  on_boot = true
  started = true

  operating_system {
    type = "l26"
  }

  agent {
    enabled = false
  }

  lifecycle {
    ignore_changes = [
      cdrom,
      disk,
    ]
  }
}

# ============================================================================
# Worker VMs (Triple-NIC)
# ============================================================================
module "workers" {
  source   = "./modules/talos-vm-triple-nic"
  for_each = local.workers_config

  vm_name      = each.value.name
  vm_id        = each.value.vm_id
  proxmox_node = var.proxmox_node

  cores  = each.value.cores
  memory = each.value.memory

  mac_address = each.value.mac_address

  network_bridge = var.network_bridge
  truenas_bridge = var.truenas_bridge
  storage_bridge = var.storage_bridge

  boot_disk_datastore = var.proxmox_storage
  boot_disk_size      = each.value.disk

  mayastor_lv_path    = each.value.mayastor_lv
  mayastor_disk_size  = each.value.mayastor_disk

  talos_iso_file_id = proxmox_virtual_environment_download_file.talos_nocloud_image.id
}

# ============================================================================
# Talos Machine Configuration Application
# ============================================================================

# Apply control plane configuration
resource "talos_machine_configuration_apply" "control_plane" {
  depends_on = [
    proxmox_virtual_environment_vm.control_plane
  ]

  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  node                        = var.control_plane.ip

  config_patches = []
}

# Apply worker configurations
resource "talos_machine_configuration_apply" "workers" {
  for_each = local.workers_config

  depends_on = [
    module.workers
  ]

  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.workers[each.key].machine_configuration
  node                        = each.value.ip

  config_patches = []
}

# ============================================================================
# Talos Cluster Bootstrap
# ============================================================================
resource "talos_machine_bootstrap" "cluster" {
  depends_on = [
    talos_machine_configuration_apply.control_plane
  ]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = var.control_plane.ip
}

# ============================================================================
# Kubeconfig Export
# ============================================================================
resource "local_file" "kubeconfig" {
  depends_on = [
    talos_machine_bootstrap.cluster
  ]

  content         = data.talos_cluster_kubeconfig.cluster.kubeconfig_raw
  filename        = "${path.module}/generated/kubeconfig"
  file_permission = "0600"
}

resource "local_file" "talosconfig" {
  content         = data.talos_client_configuration.cluster.talos_config
  filename        = "${path.module}/generated/talosconfig"
  file_permission = "0600"
}

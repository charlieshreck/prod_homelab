# ============================================================================
# ZFS Storage Pool and zvol Creation for Mayastor
# ============================================================================
# This creates the Taranaki ZFS pool and zvols on the Proxmox host
# Prerequisite: 4TB NVMe must be unbound from vfio-pci and visible as /dev/nvmeXnX

# Create Taranaki ZFS pool and zvols for Mayastor storage
resource "null_resource" "taranaki_zfs_pool" {
  # Only run if the pool doesn't already exist
  # This prevents destroying/recreating the pool on every apply

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = "root"
    password = var.proxmox_password
  }

  # Check if pool exists, create if it doesn't
  provisioner "remote-exec" {
    inline = [
      "# Check if Taranaki pool already exists",
      "if ! zpool list Taranaki &>/dev/null; then",
      "  echo 'Creating Taranaki ZFS pool...'",
      "  # Find the 4TB NVMe device (CT4000P3PSSD8)",
      "  NVME_DEVICE=$(lsblk -o NAME,SIZE,MODEL -d -n | grep -i 'CT4000P3PSSD8\\|3.6T\\|3.7T' | awk '{print \"/dev/\" $1}' | head -1)",
      "  if [ -z \"$NVME_DEVICE\" ]; then",
      "    echo 'ERROR: Could not find 4TB NVMe device. Is it unbound from vfio-pci?'",
      "    exit 1",
      "  fi",
      "  echo \"Found NVMe device: $NVME_DEVICE\"",
      "  # Create ZFS pool",
      "  zpool create -f Taranaki $NVME_DEVICE",
      "  # Set pool properties for optimal Mayastor performance",
      "  zfs set compression=off Taranaki",
      "  zfs set sync=disabled Taranaki",
      "  zfs set atime=off Taranaki",
      "  echo 'Taranaki ZFS pool created successfully'",
      "else",
      "  echo 'Taranaki pool already exists, skipping creation'",
      "fi",
      "# Verify pool status",
      "zpool status Taranaki",
      "zpool list Taranaki"
    ]
  }
}

# ZVOL PRE-CREATION COMMENTED OUT - Let Proxmox create zvols automatically
# Proxmox will create zvols when VMs are created with datastore_id="Taranaki"
#
# Create zvols for each worker with Proxmox naming convention
# Proxmox expects zvols named: vm-<vmid>-disk-<disk_number>
# Mayastor disk is SCSI1 (second disk), so disk number is 1
# resource "null_resource" "mayastor_zvols" {
#   for_each = local.workers_config
#
#   depends_on = [null_resource.taranaki_zfs_pool]
#
#   connection {
#     type     = "ssh"
#     host     = var.proxmox_host
#     user     = "root"
#     password = var.proxmox_password
#   }
#
#   # Create zvol if it doesn't exist
#   provisioner "remote-exec" {
#     inline = [
#       "# Check if zvol exists (Proxmox naming: vm-<vmid>-disk-1)",
#       "if ! zfs list Taranaki/vm-${each.value.vm_id}-disk-1 &>/dev/null; then",
#       "  echo 'Creating zvol Taranaki/vm-${each.value.vm_id}-disk-1 for ${each.key}...'",
#       "  zfs create -V ${each.value.mayastor_disk}G Taranaki/vm-${each.value.vm_id}-disk-1",
#       "  echo 'zvol created successfully'",
#       "else",
#       "  echo 'zvol Taranaki/vm-${each.value.vm_id}-disk-1 already exists, skipping creation'",
#       "fi",
#       "# Verify zvol",
#       "ls -lh /dev/zvol/Taranaki/vm-${each.value.vm_id}-disk-1"
#     ]
#   }
#
#   # Note: No destroy provisioner for safety
#   # zvols should be manually destroyed to prevent accidental data loss
#   # To manually destroy: ssh root@10.10.0.10 "zfs destroy Taranaki/vm-401-disk-1"
# }

# Output ZFS pool information
output "taranaki_pool_status" {
  description = "Taranaki ZFS pool creation status"
  value       = "ZFS pool Taranaki should be available on ${var.proxmox_host}"
  depends_on  = [null_resource.taranaki_zfs_pool]
}

# Commented out - zvols created automatically by Proxmox now
# output "mayastor_zvol_paths" {
#   description = "Paths to Mayastor zvols (Proxmox naming convention)"
#   value = {
#     for key, worker in local.workers_config :
#     key => "/dev/zvol/Taranaki/vm-${worker.vm_id}-disk-1"
#   }
#   depends_on = [null_resource.mayastor_zvols]
# }

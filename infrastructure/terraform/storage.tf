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
      "  ",
      "  # Find the 4TB NVMe device (CT4000P3PSSD8)",
      "  NVME_DEVICE=$(lsblk -o NAME,SIZE,MODEL -d -n | grep -i 'CT4000P3PSSD8\\|3.6T\\|3.7T' | awk '{print \"/dev/\" $1}' | head -1)",
      "  ",
      "  if [ -z \"$NVME_DEVICE\" ]; then",
      "    echo 'ERROR: Could not find 4TB NVMe device. Is it unbound from vfio-pci?'",
      "    exit 1",
      "  fi",
      "  ",
      "  echo \"Found NVMe device: $NVME_DEVICE\"",
      "  ",
      "  # Create ZFS pool",
      "  zpool create -f Taranaki $NVME_DEVICE",
      "  ",
      "  # Set pool properties for optimal Mayastor performance",
      "  zfs set compression=off Taranaki",
      "  zfs set sync=disabled Taranaki",
      "  zfs set atime=off Taranaki",
      "  ",
      "  echo 'Taranaki ZFS pool created successfully'",
      "else",
      "  echo 'Taranaki pool already exists, skipping creation'",
      "fi",
      "",
      "# Verify pool status",
      "zpool status Taranaki",
      "zpool list Taranaki"
    ]
  }
}

# Create zvols for each worker
resource "null_resource" "mayastor_zvols" {
  for_each = var.workers

  depends_on = [null_resource.taranaki_zfs_pool]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = "root"
    password = var.proxmox_password
  }

  # Create zvol if it doesn't exist
  provisioner "remote-exec" {
    inline = [
      "# Check if zvol exists",
      "if ! zfs list Taranaki/${each.key}-mayastor &>/dev/null; then",
      "  echo 'Creating zvol Taranaki/${each.key}-mayastor...'",
      "  zfs create -V ${each.value.mayastor_disk}G Taranaki/${each.key}-mayastor",
      "  echo 'zvol created successfully'",
      "else",
      "  echo 'zvol Taranaki/${each.key}-mayastor already exists, skipping creation'",
      "fi",
      "",
      "# Verify zvol",
      "ls -lh /dev/zvol/Taranaki/${each.key}-mayastor"
    ]
  }

  # If zvol needs to be destroyed, remove it
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "# Only destroy if zvol exists and has no dependent VMs",
      "if zfs list Taranaki/${each.key}-mayastor &>/dev/null; then",
      "  echo 'WARNING: Destroying zvol Taranaki/${each.key}-mayastor'",
      "  echo 'Ensure no VMs are using this zvol before proceeding'",
      "  # Uncomment the next line to actually destroy (safety check)",
      "  # zfs destroy Taranaki/${each.key}-mayastor",
      "fi"
    ]
  }
}

# Output ZFS pool information
output "taranaki_pool_status" {
  description = "Taranaki ZFS pool creation status"
  value       = "ZFS pool Taranaki should be available on ${var.proxmox_host}"
  depends_on  = [null_resource.taranaki_zfs_pool]
}

output "mayastor_zvol_paths" {
  description = "Paths to Mayastor zvols"
  value = {
    for key, worker in var.workers :
    key => "/dev/zvol/Taranaki/${key}-mayastor"
  }
  depends_on = [null_resource.mayastor_zvols]
}

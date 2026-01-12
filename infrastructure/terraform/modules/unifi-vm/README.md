# UniFi VM Terraform Module

Provisions a Debian VM on Proxmox for running UniFi OS Server with Podman.

## Usage

```hcl
module "unifi_vm" {
  source = "./modules/unifi-vm"

  proxmox_host     = "ruapehu"
  vm_id            = 451
  vm_name          = "unifi"
  vm_description   = "UniFi OS Server"

  cpu_cores        = 2
  memory           = 4096
  disk_size        = 50

  ip_address       = "10.10.0.51"
  gateway          = "10.10.0.1"
  mac_address      = "BC:24:11:AA:51:01"

  ssh_public_key   = file("~/.ssh/id_rsa.pub")
  root_password    = var.root_password

  cloud_init_storage = "local"
  disk_storage       = "local-lvm"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| bpg/proxmox | >= 0.38.0 |

## Providers

| Name | Version |
|------|---------|
| proxmox | >= 0.38.0 |

## Resources

| Name | Type |
|------|------|
| proxmox_virtual_environment_vm | resource |
| proxmox_virtual_environment_file | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| proxmox_host | Proxmox node name | `string` | n/a | yes |
| vm_id | VM ID | `number` | n/a | yes |
| vm_name | VM hostname | `string` | n/a | yes |
| vm_description | VM description | `string` | `""` | no |
| cpu_cores | Number of CPU cores | `number` | `2` | no |
| memory | Memory in MB | `number` | `4096` | no |
| disk_size | Disk size in GB | `number` | `50` | no |
| ip_address | Static IP address | `string` | n/a | yes |
| gateway | Default gateway | `string` | n/a | yes |
| mac_address | MAC address | `string` | n/a | yes |
| ssh_public_key | SSH public key for root | `string` | n/a | yes |
| root_password | Root password | `string` | n/a | yes |
| cloud_init_storage | Storage for cloud-init | `string` | `"local"` | no |
| disk_storage | Storage for VM disk | `string` | `"local-lvm"` | no |

## Outputs

| Name | Description |
|------|-------------|
| vm_id | The VM ID |
| ip_address | The VM IP address |
| mac_address | The VM MAC address |

## Cloud-Init

The module uses cloud-init to:
- Set hostname and timezone
- Configure root user with SSH key and password
- Install QEMU guest agent
- Configure static IP networking

## Post-Deployment

After VM creation, run the Ansible playbook to install UniFi OS:

```bash
cd /home/prod_homelab/infrastructure/ansible
ansible-playbook -i inventory/unifi.yml playbooks/unifi-os.yml
```

## Network Requirements

- VM needs outbound internet access for UniFi OS download
- Ports 8080, 11443, 3478/udp should be accessible from UniFi devices
- DHCP reservation recommended for static IP

## Notes

- Uses Debian 13 (Trixie) cloud image
- QEMU guest agent enabled for Proxmox integration
- No GPU passthrough (unlike Plex VM)
- Single NIC configuration

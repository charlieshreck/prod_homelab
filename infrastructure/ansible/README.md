# Ansible Configuration for Prod Homelab

Ansible roles and playbooks for configuring VMs and services in the production cluster.

## Structure

```
ansible/
├── inventory/           # Host inventories
│   └── unifi.yml       # UniFi OS Server inventory
├── playbooks/          # Playbooks
│   └── unifi-os.yml    # UniFi OS installation playbook
├── roles/              # Reusable roles
│   └── unifi-os/       # UniFi OS Server role
└── README.md           # This file
```

## Roles

### unifi-os

Installs UniFi OS Server on Debian 12/13 using Podman.

**Requirements:**
- Debian 12+ or Ubuntu 23.04+
- Root SSH access
- 4GB+ RAM recommended

**Variables:**
| Variable | Default | Description |
|----------|---------|-------------|
| `unifi_version` | 4.2.23 | UniFi OS version |
| `unifi_installer_url` | (see defaults) | Download URL with UUID |
| `unifi_swap_size` | 2G | Swap file size |
| `unifi_swap_enabled` | true | Enable swap creation |
| `unifi_timezone` | Europe/London | System timezone |

**Usage:**
```bash
ansible-playbook -i inventory/unifi.yml playbooks/unifi-os.yml
```

## Inventories

### unifi.yml

UniFi OS Server at 10.10.0.51 (VM 451).

```yaml
all:
  hosts:
    unifi:
      ansible_host: 10.10.0.51
      ansible_user: root
```

## Running Playbooks

```bash
cd /home/prod_homelab/infrastructure/ansible

# With host key checking disabled (first run)
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/<inventory>.yml playbooks/<playbook>.yml

# Normal run
ansible-playbook -i inventory/<inventory>.yml playbooks/<playbook>.yml

# Dry run
ansible-playbook -i inventory/<inventory>.yml playbooks/<playbook>.yml --check

# Verbose output
ansible-playbook -i inventory/<inventory>.yml playbooks/<playbook>.yml -vvv
```

## Adding New Roles

1. Create role structure:
   ```bash
   mkdir -p roles/<role-name>/{tasks,handlers,defaults,templates,files}
   ```

2. Create `tasks/main.yml` with tasks

3. Create `defaults/main.yml` with default variables

4. Create playbook in `playbooks/`

5. Create inventory in `inventory/`

6. Document in this README

## Security Notes

- Inventory files may contain passwords - do not commit to public repos
- Use Ansible Vault for sensitive data in production
- SSH keys preferred over passwords where possible

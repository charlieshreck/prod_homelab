# Ansible Configuration for Prod Homelab

Ansible roles and playbooks for configuring VMs, LXC containers, and services in the production environment.

## Structure

```
ansible/
├── inventory/
│   ├── plex.yml            # Plex Media Server VM
│   ├── unifi.yml           # UniFi OS Server VM
│   ├── omada.yml           # Omada Controller LXC
│   └── lxc.yml             # Synapse + Haute Banque LXCs
├── playbooks/
│   ├── plex-nvidia.yml     # Plex VM with Nvidia GPU
│   ├── unifi-os.yml        # UniFi OS installation
│   ├── omada.yml           # Omada controller installation
│   ├── tamar.yml           # Tamar PWA (Synapse LXC)
│   ├── hb-worker.yml       # Investmentology (HB LXC)
│   └── site.yml            # Run all playbooks
├── roles/
│   ├── lxc-base/           # Common LXC setup (packages, Infisical CLI, sysctl)
│   ├── tamar/              # Tamar Express + Redis + Infisical secret injection
│   ├── hb-worker/          # Investmentology Python + timers + screen sessions
│   ├── plex-nvidia/        # Nvidia driver + Docker + Plex container
│   ├── unifi-os/           # UniFi OS Server via Podman
│   └── omada/              # Omada SDN controller
└── README.md
```

## Roles

### lxc-base

Common setup for all LXC containers. Applied before any application-specific role.

**What it does:**
- Installs base packages (curl, git, htop, tmux, screen, jq, etc.)
- Installs Infisical CLI (from Cloudsmith apt repo)
- Sets timezone to UTC
- Configures /etc/resolv.conf to point to 10.10.0.1 (AdGuard)
- Applies sysctl optimizations (inotify watches)
- Manages SSH authorized_keys

**Variables:**
| Variable | Default | Description |
|----------|---------|-------------|
| `lxc_timezone` | UTC | System timezone |
| `dns_server` | 10.10.0.1 | DNS resolver |
| `lxc_base_packages` | (see defaults) | List of apt packages |
| `lxc_authorized_keys` | [] | SSH public keys |
| `lxc_sysctl_settings` | (see defaults) | Sysctl key-value pairs |

### tamar

Configures Tamar (Unified Estate Operations PWA) on Synapse LXC.

**What it does:**
- Installs Node.js 22 LTS from NodeSource
- Installs and configures Redis (256mb maxmemory, allkeys-lru eviction)
- Deploys tamar.service with Infisical CLI secret injection
- Hardcoded secrets (AUTH_PASSWORD, SESSION_SECRET, A2A_API_TOKEN) replaced with runtime injection

**Secret injection pattern:**
```ini
ExecStart=/bin/bash -c 'eval $(infisical export --env=prod --path=/platform/tamar --format=dotenv-export) && exec /usr/bin/node server.js'
```

**Variables:**
| Variable | Default | Description |
|----------|---------|-------------|
| `tamar_port` | 3456 | Application port |
| `tamar_node_env` | production | NODE_ENV value |
| `tamar_infisical_path` | /platform/tamar | Infisical secret path |
| `redis_maxmemory` | 256mb | Redis memory limit |
| `tamar_error_hunter_url` | http://10.20.0.40:30801 | Error Hunter endpoint |

**Usage:**
```bash
ansible-playbook -i inventory/lxc.yml playbooks/tamar.yml
```

### hb-worker

Configures Investmentology platform on Haute Banque LXC.

**What it does:**
- Installs Python 3.12+ and Node.js 22
- Deploys 3 long-running services: investmentology, synapse-hb, screens
- Deploys 6 timer/service pairs for scheduled analysis jobs
- synapse-hb.service uses Infisical for AUTH_CREDENTIALS injection

**Services:**
| Service | Type | Description |
|---------|------|-------------|
| investmentology | simple | FastAPI server (port 80) |
| synapse-hb | simple | Screen monitor PWA (port 3460) |
| screens | oneshot+remain | GNU Screen sessions |

**Timers:**
| Timer | Schedule | Description |
|-------|----------|-------------|
| daily-analyze | Mon-Fri 05:30 UTC | Watchlist re-analysis |
| monitor | Mon-Fri 16:15 ET | Post-market monitor |
| premarket | Mon-Fri 08:00 ET | Pre-market stop-loss check |
| price-refresh | Mon-Fri hourly 14:30-21:00 UTC | Intraday price refresh |
| screen | Sun 06:00 UTC | Weekly stock screen |
| post-screen | Sun 07:00 UTC | Post-screen analysis |

**Usage:**
```bash
ansible-playbook -i inventory/lxc.yml playbooks/hb-worker.yml
```

### plex-nvidia

Configures Plex Media Server VM with Nvidia GPU passthrough.

**Usage:**
```bash
ansible-playbook -i inventory/plex.yml playbooks/plex-nvidia.yml
```

### unifi-os

Installs UniFi OS Server on Debian 12/13 using Podman.

**Usage:**
```bash
ansible-playbook -i inventory/unifi.yml playbooks/unifi-os.yml
```

### omada

Installs TP-Link Omada SDN Controller on Debian 12 LXC.

**Usage:**
```bash
ansible-playbook -i inventory/omada.yml playbooks/omada.yml --ask-pass
```

## Inventories

### lxc.yml

Both LXC containers managed by Ansible:
- **synapse-lxc** (10.10.0.22) - Synapse LXC on Pihanga, runs Tamar
- **hb-lxc** (10.10.0.101) - Haute Banque LXC on Hikurangi, runs Investmentology

Note: HB LXC uses ProxyJump through Hikurangi (10.10.0.178) since it is not directly reachable.

### plex.yml

Plex Media Server at 10.10.0.50 (VM 450 on Ruapehu).

### unifi.yml

UniFi OS Server at 10.10.0.51 (VM 451 on Ruapehu).

### omada.yml

Omada Software Controller at 10.10.0.3 (LXC 200 on Ruapehu).

## Running Playbooks

```bash
cd /home/prod_homelab/infrastructure/ansible

# Run individual playbook
ansible-playbook -i inventory/lxc.yml playbooks/tamar.yml
ansible-playbook -i inventory/lxc.yml playbooks/hb-worker.yml

# Run all playbooks (requires all inventories)
ansible-playbook -i inventory/plex.yml -i inventory/lxc.yml playbooks/site.yml

# With host key checking disabled (first run)
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory/lxc.yml playbooks/tamar.yml

# Dry run
ansible-playbook -i inventory/lxc.yml playbooks/tamar.yml --check

# Verbose output
ansible-playbook -i inventory/lxc.yml playbooks/tamar.yml -vvv
```

## Security Notes

- Secrets are injected at runtime via Infisical CLI -- never stored in Ansible files
- The `lxc-base` role installs Infisical CLI on all managed containers
- Inventory files do not contain passwords (use --ask-pass or SSH keys)
- SSH keys preferred over passwords where possible
- Infisical paths: `/platform/tamar` (Synapse), `/platform/haute-banque` (HB)

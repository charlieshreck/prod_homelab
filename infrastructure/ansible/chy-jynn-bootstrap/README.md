# Chy-Jynn Bootstrap Playbook

**Chy-Jynn** (Cornish: "engine house") is the control environment for the Kernow homelab. This Ansible playbook provisions a fresh Debian LXC into a fully functional infrastructure management environment.

## What it installs

- **CLI Tools**: kubectl, talosctl, terraform, helm, argocd, yq
- **Development**: git, neovim, ansible, nodejs, npm, python3
- **Utilities**: ripgrep, fd-find, bat, jq, screen, fzf
- **AI Tools**: Claude Code CLI, Gemini CLI
- **Custom Scripts**: Symlinked from `/home/dotfiles/scripts/`
- **Configuration**: Symlinked from `/home/dotfiles/`

## Configuration as Code

All chy-jynn configuration lives in `/home/dotfiles/` (the kernow-homelab parent repo):

```
/home/dotfiles/
├── scripts/           → /usr/local/bin/
├── profile.d/         → /etc/profile.d/
├── claude-ref/        → /root/.claude-ref/
├── bashrc             → /root/.bashrc
└── gitconfig          → /root/.gitconfig
```

Changes to scripts/config are made in `/home/dotfiles/`, committed to git, and immediately available.

## Disaster Recovery

### Option 1: From any machine with Ansible

```bash
# 1. On Proxmox - create minimal LXC
ssh root@10.10.0.10
pct create 100 local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst \
  --hostname chy-jynn \
  --memory 6144 \
  --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=10.10.0.100/24,gw=10.10.0.1 \
  --storage local-lvm \
  --rootfs local-lvm:50 \
  --features nesting=1 \
  --start 1

# 2. From your laptop (or any machine with ansible)
git clone git@github.com:charlieshreck/homelab-prod.git
cd homelab-prod/infrastructure/ansible
ansible-playbook -i "10.10.0.100," chy-jynn-bootstrap/playbook.yml -u root
```

### Option 2: Self-bootstrap from inside the LXC

```bash
# After creating and starting the LXC, SSH in:
apt update && apt install -y git ansible
git clone https://github.com/charlieshreck/homelab-prod.git /tmp/bootstrap
cd /tmp/bootstrap/infrastructure/ansible
ansible-playbook chy-jynn-bootstrap/playbook.yml --connection=local

# Clone the actual repos (after adding SSH key)
rm -rf /home/*
cd /home
git clone --recurse-submodules git@github.com:charlieshreck/kernow-homelab.git .
```

## Post-bootstrap Steps

1. **SSH Keys**: Copy your SSH keys or generate new ones
2. **Infisical**: Run `/root/.config/infisical/get-token.sh` to authenticate
3. **Claude Code**: Run `claude` and authenticate
4. **Verify clusters**: Run `cluster-health` to check all clusters

## Updating Configuration

Configuration changes should be made to the dotfiles in `/home/dotfiles/`, not the symlinked locations:

```bash
# Edit a script
nvim /usr/local/bin/cluster-health  # Actually edits /home/dotfiles/scripts/cluster-health

# Commit (must use repo path)
git -C /home add dotfiles/scripts/cluster-health
git -C /home commit -m "update cluster-health"
git -C /home push
```

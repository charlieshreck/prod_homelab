# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a production Kubernetes homelab deployment on Proxmox using GitOps principles. The infrastructure consists of:
- **Talos Linux** Kubernetes cluster (1 control plane + 3 workers)
- **Plex Media Server** VM with Nvidia P4000 GPU passthrough
- **GitOps** via ArgoCD for all Kubernetes resources
- **Secrets management** via Infisical
- **Multi-network architecture** with dedicated 40GbE internal networks for storage

**Critical principle**: NEVER make manual infrastructure changes. Everything must be defined in code (Terraform, Ansible, Kubernetes manifests), version controlled, and automated.

## Architecture

### Network Design
Three Proxmox bridges with specific purposes:
- **vmbr0** (10.10.0.0/24): Management/external network via physical NIC
- **vmbr3** (10.40.0.0/24): Internal 40GbE network for TrueNAS NFS traffic (MTU 9000)
- **vmbr4** (10.50.0.0/24): Internal 40GbE network for Mayastor replication only

Workers have **triple NIC configuration**:
1. eth0 (vmbr0) - Management and default route
2. eth1 (vmbr3) - TrueNAS NFS mounts
3. eth2 (vmbr4) - Mayastor inter-node replication

Control plane has single NIC (vmbr0 only). Plex VM has dual NIC (vmbr0 + vmbr3) plus GPU passthrough.

### Storage Architecture
- **Mayastor**: High-performance replicated block storage on vmbr4 network
  - Each worker has dedicated 400GB disk for Mayastor pool
  - 3-way replication across workers via isolated 10.50.0.0/24 network
- **TrueNAS NFS**: Shared media storage accessible via vmbr3 (10.40.0.10)
  - Mounted on workers and Plex VM
  - High MTU (9000) for optimal performance

### GPU Passthrough
Nvidia Quadro P4000 (PCI 0d:00.0) passed to Plex VM:
- IOMMU enabled on Proxmox host (`intel_iommu=on iommu=pt`)
- GPU bound to vfio-pci driver (IDs: `10de:1bb1,10de:10f0`)
- Plex uses nvidia-container-toolkit for hardware transcoding

## Repository Structure

```
infrastructure/
├── terraform/          # Proxmox VM provisioning
│   ├── modules/
│   │   ├── talos-vm/          # Talos cluster VMs
│   │   └── plex-vm-nvidia/    # Plex VM with GPU
│   ├── main.tf
│   ├── plex.tf
│   └── terraform.tfvars       # NEVER COMMIT - contains secrets
├── ansible/            # Plex VM configuration
│   ├── inventory/
│   ├── playbooks/
│   └── roles/
│       └── plex-nvidia/       # Nvidia driver + Docker setup
└── scripts/
    ├── maintenance/
    └── diagnostic/

kubernetes/
├── argocd-apps/        # ArgoCD Application manifests
│   ├── platform/              # Core infrastructure apps
│   └── applications/          # User-facing apps
├── platform/           # Platform component configs
│   ├── argocd/
│   ├── cert-manager/
│   ├── traefik/
│   ├── mayastor/
│   ├── infisical/
│   └── cloudflared/
└── applications/       # Application configs
    └── media/
```

## Development Workflow

### Terraform Operations
```bash
cd infrastructure/terraform

# Always validate before applying
terraform init
terraform validate
terraform fmt -recursive

# Plan with explicit output file
terraform plan -out=prod.plan

# Apply from plan file
terraform apply prod.plan

# Target specific resources
terraform apply -target=module.plex

# Export kubeconfig after cluster creation
export KUBECONFIG=$(pwd)/generated/kubeconfig
```

### Ansible Operations
```bash
cd infrastructure/ansible

# Syntax check
ansible-playbook --syntax-check playbooks/plex-nvidia.yml

# Run with inventory
ansible-playbook -i inventory/plex.yml playbooks/plex-nvidia.yml

# Check mode (dry run)
ansible-playbook -i inventory/plex.yml playbooks/plex-nvidia.yml --check
```

### Kubernetes Operations
```bash
# NEVER kubectl apply manually - use ArgoCD!
# Only use kubectl for read operations and verification

# Check ArgoCD applications
kubectl get applications -n argocd

# Force sync an application
kubectl -n argocd get app <app-name> -o yaml

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward to ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Talos Operations
```bash
# Get node configuration
talosctl -n <node-ip> get links
talosctl -n <node-ip> get addresses
talosctl -n <node-ip> get routes

# Check disk availability
talosctl -n <node-ip> disks

# Dashboard
talosctl -n <node-ip> dashboard

# Get logs
talosctl -n <node-ip> logs <service-name>
```

## Critical Configuration Patterns

### Talos Triple-NIC Worker Configuration
Terraform MUST create network devices in exact order:
1. First `network_device` block → eth0 (vmbr0)
2. Second `network_device` block → eth1 (vmbr3)
3. Third `network_device` block → eth2 (vmbr4)

Talos machine config must define all interfaces with correct IPs and MTU:
```yaml
machine:
  network:
    interfaces:
      - interface: eth0
        addresses: [10.10.0.4X/24]
        routes: [{network: 0.0.0.0/0, gateway: 10.10.0.1}]
      - interface: eth1
        addresses: [10.40.0.4X/24]
        mtu: 9000
      - interface: eth2
        addresses: [10.50.0.4X/24]
```

### InfisicalSecret Pattern
All Kubernetes secrets sourced from Infisical:
```yaml
apiVersion: secrets.infisical.com/v1alpha1
kind: InfisicalSecret
metadata:
  name: secret-name
  namespace: target-namespace
spec:
  hostAPI: https://app.infisical.com/api
  authentication:
    universalAuth:
      credentialsRef:
        secretName: universal-auth-credentials
        secretNamespace: infisical-operator-system
      secretsScope:
        projectSlug: prod-homelab-y-nij  # CRITICAL: Actual project slug
        envSlug: prod
        secretsPath: /path
  managedSecretReference:
    secretName: secret-name
    secretNamespace: target-namespace
    secretType: Opaque
    creationPolicy: Owner
```

**Infisical Project Details:**
- Project Name: `prod_homelab`
- Project Slug: `prod-homelab-y-nij` (use in Kubernetes manifests)
- Project ID: `9383e039-68ca-4bab-bc3c-aa06fdb82627` (use in REST API)
- Environment: `prod`
- Service Token: `st.a46273f4-351c-4f5e-8de3-1e5f40391ffe...`

**Verify secrets:**
```bash
export INFISICAL_SERVICE_TOKEN="st.a46273f4-351c-4f5e-8de3-1e5f40391ffe.31920c113fa1e30fe99d6600ce7d77f5.15ecd6e9e8a199249b850c5b14e809df"
./scripts/verify-infisical-secrets.sh
```

**Check current status:**
```bash
cat docs/INFISICAL-STATUS.md
```

### GPU Passthrough in Terraform
```hcl
hostpci {
  device = "hostpci0"
  id     = "0000:0d:00"  # P4000 PCI address
  pcie   = true
  rombar = true
}
```

### Plex Docker Compose Pattern
```yaml
services:
  plex:
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
    devices:
      - /dev/nvidia0
      - /dev/nvidiactl
      - /dev/nvidia-uvm
    volumes:
      - /dev/shm:/transcode  # RAM disk for transcoding
      - /mnt/media:/data:ro  # NFS mount via 10.40.0.10
```

## Deployment Order

**MUST follow this sequence:**

1. **Manual setup** (one-time only):
   - Create vmbr4 bridge on Proxmox
   - Configure Infisical project and secrets
   - Setup Cloudflare tunnel

2. **Terraform apply**: Creates VMs, bootstraps Talos cluster (~20 minutes)

3. **Export kubeconfig**: From `infrastructure/terraform/generated/kubeconfig`

4. **Verify cluster**: Nodes ready, ArgoCD running

5. **Ansible playbook**: Configure Plex VM with Nvidia drivers

6. **ArgoCD sync**: Platform apps → Application apps

7. **Verification**: Certificates, ingress, GPU transcoding, Mayastor

8. **Cleanup legacy VMs**: Only after 1 week stable operation

## Verification Commands

```bash
# Cluster health
kubectl get nodes
kubectl get pods -A

# ArgoCD status
kubectl get applications -n argocd

# Certificates
kubectl get certificates -A

# Mayastor
kubectl get diskpool -n mayastor
kubectl get storageclass

# Plex GPU
ssh root@10.10.0.50 nvidia-smi
ssh root@10.10.0.50 nvidia-smi dmon -s u  # Monitor during transcode

# NFS mounts
ssh root@10.10.0.50 df -h /mnt/media
showmount -e 10.40.0.10
```

## Common Issues

### Workers not getting correct IPs
- Verify NIC order in Terraform matches Talos config
- Check: `talosctl -n <ip> get links`
- Static IPs must be configured in Talos machine config

### GPU not visible in Plex
- Check IOMMU group: `find /sys/kernel/iommu_groups/ -type l`
- Verify vfio binding: `lspci -nnk | grep -A3 "0d:00"`
- VM config: `qm config 450 | grep hostpci`
- Inside VM: `nvidia-smi`

### NFS mount failures
- Test from VM: `showmount -e 10.40.0.10`
- Check vmbr3 connectivity: `ip route get 10.40.0.10`
- TrueNAS export must include 10.40.0.0/24 network

### Mayastor pool offline
- Check vmbr4 NICs: `kubectl exec -n mayastor <pod> -- ip addr show eth2`
- Verify 10.50.0.0/24 routing between workers
- Check disk: `talosctl -n <worker-ip> disks`

## Security Rules

1. **NEVER commit** `terraform.tfvars` - contains Proxmox credentials
2. **ALWAYS use Infisical** for Kubernetes secrets - no hardcoded secrets
3. **NEVER kubectl apply** directly - all deployments via ArgoCD
4. **ALWAYS commit to Git first** - let GitOps sync changes
5. **Plex claim token expires in 4 minutes** - get fresh from https://plex.tv/claim

## Key Files

- `infrastructure/terraform/terraform.tfvars` - Secrets (gitignored)
- `infrastructure/terraform/locals.tf` - Network/IP allocation logic
- `infrastructure/terraform/modules/talos-vm/` - Worker NIC configuration
- `infrastructure/ansible/roles/plex-nvidia/` - GPU setup automation
- `kubernetes/argocd-apps/` - ArgoCD Application definitions
- `kubernetes/platform/infisical/` - Operator and auth config

## External Dependencies

- **Proxmox host**: Ruapehu (10.10.0.10) - root@pam
- **TrueNAS**: 10.10.0.100 (mgmt), 10.40.0.10 (NFS)
- **Infisical**: https://app.infisical.com - project: prod_homelab (slug: prod-homelab-y-nij, ID: 9383e039-68ca-4bab-bc3c-aa06fdb82627)
- **Cloudflare**: Domain: kernow.io
- **Git**: https://github.com/charlieshreck/homelab-prod.git
- **Reference repo**: https://github.com/charlieshreck/homelab-test (shreck.co.uk)

## Resource Limits

Total hardware budget (Ruapehu host):
- **CPU**: 24 threads (i9-12900K) - ALL ALLOCATED
- **RAM**: 62GB - FULLY ALLOCATED
- **Storage**: 250GB NVMe (local) + 1.8TB NVMe ZFS (Ranginui)

Do not increase VM allocations without reducing elsewhere.

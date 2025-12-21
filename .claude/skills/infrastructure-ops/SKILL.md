---
name: infrastructure-ops
description: Production homelab infrastructure operations. Use when managing VMs, containers, Kubernetes, Talos, networking, or troubleshooting infrastructure issues.
allowed-tools: All
---

# Production Homelab Infrastructure Operations

## Common Queries & Default Prompts

### Proxmox Management
- "List all VMs and their resource usage on Ruapehu"
- "Show LXC containers on Carrick monitoring host"
- "Check disk usage on both Proxmox hosts"
- "Show the status of VM 450 (Plex with GPU passthrough)"
- "List all storage pools on Ruapehu"
- "Check CPU and memory allocation across all VMs"

### Kubernetes Operations
- "List all failing pods across all namespaces in prod cluster"
- "Show ArgoCD application sync status"
- "Check certificate expiration dates"
- "Get logs from the homepage pod"
- "Describe the homepage deployment and its dual ingresses"
- "Show all applications in the media namespace"
- "Check Mayastor storage pool status"

### Talos OS Operations
- "Check health of all Talos nodes"
- "Show etcd cluster status"
- "Get system logs from talos-worker-1"
- "Show disk usage on all Talos workers"
- "Check Talos node network configuration (triple-NIC setup)"
- "Verify Mayastor disk availability on workers"
- "Show Talos version on all nodes"

### Network Operations
- "Show current firewall rules on OPNsense"
- "List all connected UniFi clients"
- "Show top blocked domains on AdGuard"
- "Check bandwidth usage on the main UniFi switch"
- "Show VPN connections status"
- "List all UniFi WiFi networks and their settings"

### Storage Operations
- "Check NFS mounts from TrueNAS on workers"
- "Show Mayastor pool status and capacity"
- "List all PVCs and their storage classes"
- "Check TrueNAS dataset usage"
- "Verify vmbr3 (10.40.0.0/24) network for NFS traffic"

### GPU Passthrough (Plex VM)
- "Check Nvidia GPU status on Plex VM"
- "Show GPU utilization during transcoding"
- "Verify GPU device visibility in Plex VM"
- "Check Plex Docker container GPU access"

## Architecture Context

### Network Layout
- **Production**: 10.10.0.0/24 (vmbr0 - Ruapehu, Talos cluster, TrueNAS)
- **Monitoring**: 10.30.0.0/24 (vmbr0 - Carrick, K3s monitoring)
- **Storage**: 10.40.0.0/24 (vmbr3 - TrueNAS NFS, 40GbE, MTU 9000)
- **Mayastor**: 10.50.0.0/24 (vmbr4 - Replicated block storage between workers)

### Key Infrastructure IPs
- **Proxmox Ruapehu**: 10.10.0.10 (production host)
- **Proxmox Carrick**: 10.30.0.10 (monitoring host)
- **Talos CP1**: 10.10.0.40 (control plane)
- **Talos Workers**: 10.10.0.41-43 (triple-NIC: eth0/eth1/eth2)
- **K3s Monitoring**: 10.30.0.20 (single-node)
- **TrueNAS (prod)**: 10.10.0.100 (mgmt), 10.40.0.10 (NFS)
- **TrueNAS (monitoring)**: 10.30.0.120
- **Plex VM**: 10.10.0.50 (with GPU passthrough)

### Talos Worker Triple-NIC Configuration
Each worker has THREE network interfaces (order critical):
1. **eth0** (vmbr0): Management, default route (10.10.0.0/24)
2. **eth1** (vmbr3): TrueNAS NFS mounts, 40GbE (10.40.0.0/24, MTU 9000)
3. **eth2** (vmbr4): Mayastor replication traffic (10.50.0.0/24)

### Storage Architecture
- **Mayastor**: Replicated block storage (3-way replication)
  - Each worker: 400GB dedicated disk
  - Network: vmbr4 (10.50.0.0/24) for inter-node replication
  - StorageClass: mayastor-3-replica

- **TrueNAS NFS**: Shared media storage
  - Access via vmbr3 (10.40.0.10)
  - Mounted on workers and Plex VM
  - High MTU (9000) for performance

- **Local-Path**: K3s default storage (monitoring cluster)

### GPU Passthrough Setup
- **GPU**: Nvidia Quadro P4000 (PCI 0d:00.0)
- **VM**: Plex (VM ID 450)
- **Driver**: vfio-pci (IDs: 10de:1bb1,10de:10f0)
- **Host**: IOMMU enabled (intel_iommu=on iommu=pt)
- **Container**: nvidia-container-toolkit for transcoding

## Critical Deployment Patterns

### 1. Dual-Ingress Pattern (MANDATORY)
Every application MUST have TWO ingress resources:
- `ingress.yaml`: Traefik ingress class (internal LAN access)
- `cloudflare-tunnel-ingress.yaml`: Cloudflare-tunnel ingress class (external internet)

Both point to the same Service, different ingress classes.
See: `/home/prod_homelab/docs/DUAL-INGRESS-PATTERN.md`

### 2. InfisicalSecret Pattern (MANDATORY)
All Kubernetes secrets MUST come from Infisical:
- **Project**: prod_homelab
- **Slug**: prod-homelab-y-nij (CRITICAL: use slug, not project name!)
- **Environment**: prod
- **Paths**: `/`, `/kubernetes`, `/backups`, `/media`, etc.

```yaml
apiVersion: secrets.infisical.com/v1alpha1
kind: InfisicalSecret
metadata:
  name: <secret-name>
  namespace: <namespace>
spec:
  hostAPI: https://app.infisical.com/api
  authentication:
    universalAuth:
      credentialsRef:
        secretName: universal-auth-credentials
        secretNamespace: infisical-operator-system
      secretsScope:
        projectSlug: prod-homelab-y-nij  # EXACTLY this slug!
        envSlug: prod
        secretsPath: /<path>
  managedSecretReference:
    secretName: <secret-name>
    secretNamespace: <namespace>
    secretType: Opaque
    creationPolicy: Owner
```

### 3. GitOps Workflow (MANDATORY)
- **NEVER** manual infrastructure changes
- **NEVER** kubectl apply directly (except debugging)
- **ALWAYS** commit to git first
- **ALWAYS** let ArgoCD sync changes
- All infrastructure defined in code (Terraform, Ansible, K8s manifests)

## Common Workflows

### 1. Deploy New Application
```
1. Create namespace and manifests
2. Create InfisicalSecret for credentials
3. Create deployment with resource limits
4. Create dual-ingress resources (Traefik + Cloudflare)
5. Create ArgoCD Application
6. Commit to git, let ArgoCD sync
7. Verify: pods running, ingress working, certificates issued
```

### 2. Troubleshoot Network Issue
```
1. Check OPNsense firewall rules:
   "Show firewall rules for traffic to <destination>"

2. Verify UniFi network status:
   "Check UniFi switch/AP status for <device>"

3. Check DNS resolution:
   "Show AdGuard query logs for <domain>"

4. Test connectivity from Talos nodes:
   "Check if talos-worker-1 can reach <ip>"

5. Verify routing:
   "Show routes on talos-worker-1"
```

### 3. Investigate Performance Issue
```
1. Check Proxmox host resources:
   "Show CPU and memory usage on Ruapehu"

2. Check Talos node resources:
   "Show resource usage on all Talos nodes"

3. Check storage performance:
   "Show Mayastor pool latency"
   "Check NFS mount response time"

4. Check application metrics via Coroot MCP:
   "Show CPU usage for <pod> in last hour"

5. Check GPU utilization (if Plex):
   "Show Nvidia GPU usage on Plex VM"
```

### 4. Add New VM or Container
```
1. Check available resources:
   "Show available CPU/RAM on Ruapehu"

2. Plan resource allocation (total budget: 24 CPU, 62GB RAM - FULLY ALLOCATED)

3. Update Terraform configuration

4. Run terraform plan, review changes

5. Apply via terraform apply

6. Verify VM/container creation

7. Configure via Ansible if needed
```

### 5. Manage Secrets
```
1. Never add secrets to git or manifests

2. Add to Infisical UI:
   - Project: prod_homelab (slug: prod-homelab-y-nij)
   - Environment: prod
   - Path: appropriate folder

3. Create InfisicalSecret CR in K8s

4. Verify secret sync:
   "Check InfisicalSecret status in <namespace>"

5. Check application can access secret
```

## Verification Commands

### Cluster Health
- "Check all nodes are Ready in prod cluster"
- "Show pod status across all namespaces"
- "Check ArgoCD application health"

### Certificates
- "List all certificates and expiration dates"
- "Check cert-manager ClusterIssuer status"

### Storage
- "Show Mayastor DiskPool status"
- "List all PVCs and their bound status"
- "Check NFS mount points on workers"

### GPU (Plex)
- "Show GPU status in Plex VM (nvidia-smi)"
- "Check GPU utilization during transcode"
- "Verify GPU device in Plex container"

### Network
- "Check OPNsense interface status"
- "Show UniFi client count"
- "List AdGuard blocked queries"

## Security & Best Practices

1. **NEVER commit secrets** (terraform.tfvars, kubeconfig, talosconfig)
2. **ALWAYS use Infisical** for K8s secrets (projectSlug: prod-homelab-y-nij)
3. **NEVER kubectl apply** directly (use GitOps via ArgoCD)
4. **ALWAYS commit to git first** before any infrastructure change
5. **Resource limits**: Total allocated = 24 CPU, 62GB RAM (no more available!)

## Key Documentation Files
- `/home/prod_homelab/CLAUDE.md` - Main project overview
- `/home/prod_homelab/docs/DUAL-INGRESS-PATTERN.md` - Ingress pattern
- `/home/prod_homelab/docs/INFISICAL-SETUP.md` - Secrets management
- `/home/prod_homelab/infrastructure/terraform/` - VM provisioning
- `/home/prod_homelab/kubernetes/` - K8s manifests and ArgoCD apps

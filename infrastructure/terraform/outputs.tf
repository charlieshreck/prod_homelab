# ============================================================================
# Terraform Outputs
# ============================================================================

# Cluster Information
output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = local.cluster_endpoint
}

# Control Plane
output "control_plane_ip" {
  description = "Control plane node IP address"
  value       = var.control_plane.ip
}

output "control_plane_vm_id" {
  description = "Control plane VM ID"
  value       = proxmox_virtual_environment_vm.control_plane.vm_id
}

# Worker Nodes
output "worker_ips" {
  description = "Worker node IP addresses (management network)"
  value = {
    for key, worker in local.workers_config : key => worker.ip
  }
}

output "worker_truenas_ips" {
  description = "Worker node TrueNAS NFS network IPs"
  value = {
    for key, worker in local.workers_config : key => worker.truenas_ip
  }
}

output "worker_storage_ips" {
  description = "Worker node Mayastor replication network IPs"
  value = {
    for key, worker in local.workers_config : key => worker.storage_ip
  }
}

output "worker_vm_ids" {
  description = "Worker VM IDs in Proxmox"
  value = {
    for key, worker in module.workers : key => worker.vm_id
  }
}

# Mayastor Configuration
output "mayastor_nodes" {
  description = "Mayastor storage node configuration"
  value = {
    for key, node in local.mayastor_nodes : key => {
      node_name    = node.node_name
      storage_ip   = node.storage_ip
      disk_device  = node.disk_device
      pool_name    = node.pool_name
      disk_size_gb = node.disk_size_gb
    }
  }
}

# Kubeconfig (disabled - data source hangs, use /root/.kube/config)
# output "kubeconfig_path" {
#   description = "Path to generated kubeconfig file"
#   value       = local_file.kubeconfig.filename
# }

output "talosconfig_path" {
  description = "Path to generated talosconfig file"
  value       = local_file.talosconfig.filename
}

# Network Information
output "cilium_lb_ip_pool" {
  description = "Cilium LoadBalancer IP pool"
  value       = var.cilium_lb_ip_pool
}

output "network_summary" {
  description = "Network configuration summary"
  value = {
    management = {
      network = local.networks.management.network
      bridge  = local.networks.management.bridge
      gateway = local.networks.management.gateway
    }
    truenas = {
      network = local.networks.truenas.network
      bridge  = local.networks.truenas.bridge
      mtu     = local.networks.truenas.mtu
    }
    mayastor = {
      network = local.networks.mayastor.network
      bridge  = local.networks.mayastor.bridge
      mtu     = local.networks.mayastor.mtu
    }
  }
}

# GitOps Configuration
output "gitops_repository" {
  description = "GitOps repository information"
  value = {
    url    = local.gitops.repo_url
    branch = local.gitops.branch
    path   = local.gitops.path
  }
}

# Quick Start Commands
output "quick_start_commands" {
  description = "Quick start commands for cluster access"
  value       = <<-EOT
    # Export kubeconfig (use unified config, not generated)
    export KUBECONFIG=/root/.kube/config
    kubectl config use-context admin@homelab-prod

    # Check cluster nodes
    kubectl get nodes

    # Check Talos cluster health
    talosctl --talosconfig ${local_file.talosconfig.filename} health

    # ArgoCD bootstrap (after platform is ready)
    kubectl apply -k ../kubernetes/platform/argocd/
    kubectl apply -f ../kubernetes/bootstrap/app-of-apps.yaml
  EOT
}

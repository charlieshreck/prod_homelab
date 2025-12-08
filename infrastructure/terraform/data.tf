# Proxmox node data source
data "proxmox_virtual_environment_nodes" "available" {}

# Generate Talos machine secrets
resource "talos_machine_secrets" "cluster" {
}

# Talos Control Plane Configuration
data "talos_machine_configuration" "control_plane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  docs     = false
  examples = false

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = "ghcr.io/siderolabs/installer:${var.talos_version}"
        }
        network = {
          hostname = var.control_plane.name
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = ["${var.control_plane.ip}/24"]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = var.prod_gateway
                }
              ]
            }
          ]
          nameservers = var.dns_servers
        }
        kubelet = {
          nodeIP = {
            validSubnets = ["${var.control_plane.ip}/32"]
          }
        }
      }
      cluster = {
        network = {
          cni = {
            name = "none"  # Using Cilium
          }
        }
        proxy = {
          disabled = true  # Cilium replaces kube-proxy
        }
      }
    })
  ]
}

# Talos Worker Configurations (Triple-NIC)
data "talos_machine_configuration" "workers" {
  for_each = local.workers_config

  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  docs     = false
  examples = false

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = "ghcr.io/siderolabs/installer:${var.talos_version}"
        }
        network = {
          hostname = each.value.name
          interfaces = [
            {
              interface = "eth0"
              dhcp      = false
              addresses = ["${each.value.ip}/24"]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = var.prod_gateway
                }
              ]
            },
            {
              interface = "ens19"
              dhcp      = false
              addresses = ["${each.value.truenas_ip}/24"]
              mtu       = 9000
            },
            {
              interface = "ens20"
              dhcp      = false
              addresses = ["${each.value.storage_ip}/24"]
            }
          ]
          nameservers = var.dns_servers
        }
        kubelet = {
          nodeIP = {
            validSubnets = ["${each.value.ip}/32"]
          }
          # Mount /var/local for OpenEBS LocalPV (etcd, loki storage)
          extraMounts = [
            {
              destination = "/var/local"
              type        = "bind"
              source      = "/var/local"
              options     = ["rbind", "rshared", "rw"]
            }
          ]
        }
        # Mayastor requires hugepages
        sysctls = {
          "vm.nr_hugepages" = "1024"
        }
        # Label nodes for Mayastor io-engine daemonset
        nodeLabels = {
          "openebs.io/engine" = "mayastor"
        }
      }
      cluster = {
        network = {
          cni = {
            name = "none"  # Using Cilium
          }
        }
        proxy = {
          disabled = true  # Cilium replaces kube-proxy
        }
      }
    })
  ]
}

# Talos Client Configuration
data "talos_client_configuration" "cluster" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoints            = [var.control_plane.ip]
  nodes                = concat([var.control_plane.ip], [for w in local.workers_config : w.ip])
}

# Talos Cluster Kubeconfig
data "talos_cluster_kubeconfig" "cluster" {
  depends_on = [
    talos_machine_bootstrap.cluster
  ]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoint             = var.control_plane.ip
  node                 = var.control_plane.ip
}

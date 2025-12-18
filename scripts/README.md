# Scripts Directory

Utility scripts for managing the production homelab infrastructure.

## Homepage Management

### `sync-monitoring-kubeconfig.sh`

**Purpose:** Synchronizes monitoring cluster credentials for Homepage multi-cluster display.

**When to run:**
- Initial setup: After deploying Homepage and the monitoring cluster
- Token refresh: When the monitoring cluster token expires (every 100 years)
- Troubleshooting: If Homepage shows incorrect data for the monitoring cluster
- After rebuilding: If either cluster is rebuilt from scratch

**What it does:**
1. Extracts service account token from monitoring cluster (`homepage` SA in `homepage` namespace)
2. Extracts CA certificate from monitoring cluster kubeconfig
3. Creates/updates `homepage-monitoring-kubeconfig` secret in production cluster
4. Restarts Homepage deployment to pick up new credentials
5. Verifies credentials work before applying

**Requirements:**
- Monitoring cluster kubeconfig at `/home/monit_homelab/terraform/talos-single-node/generated/kubeconfig`
- Production cluster kubeconfig at `/home/prod_homelab/infrastructure/terraform/generated/kubeconfig`
- Homepage RBAC deployed in monitoring cluster (via ArgoCD app `homepage-rbac-monitoring`)

**Usage:**
```bash
cd /home/prod_homelab
./scripts/sync-monitoring-kubeconfig.sh
```

**Output:** Homepage dashboard will show:
- **Application Cluster**: 4 nodes (talos-cp-01, talos-worker-01, talos-worker-02, talos-worker-03)
- **Monitoring Cluster**: 1 node (talos-monitor)

---

### `update-homepage.sh`

**Purpose:** Apply Homepage configuration changes and restart deployment.

**When to run:**
- After modifying `/home/prod_homelab/kubernetes/applications/apps/homepage/config.yaml`
- When Homepage configuration changes aren't being picked up automatically

**Usage:**
```bash
cd /home/prod_homelab
./scripts/update-homepage.sh
```

---

## Infisical Management

### `verify-infisical-secrets.sh`

**Purpose:** Verify all secrets are properly stored in Infisical.

**Usage:**
```bash
cd /home/prod_homelab
./scripts/verify-infisical-secrets.sh
```

---

### `test-infisical-envs.sh`

**Purpose:** Test Infisical environment configuration.

**Usage:**
```bash
cd /home/prod_homelab
./scripts/test-infisical-envs.sh
```

---

## Best Practices

1. **Version Control:** All scripts are version controlled in Git
2. **IaC Compliance:** Scripts replace manual `kubectl` operations
3. **Documentation:** Each script includes inline comments and usage info
4. **Error Handling:** Scripts use `set -e` and validate prerequisites
5. **Idempotent:** Scripts can be run multiple times safely
6. **Audit Trail:** Git history provides full audit trail of changes

## Adding New Scripts

When creating new scripts:
1. Add to this directory: `/home/prod_homelab/scripts/`
2. Include shebang: `#!/bin/bash`
3. Add usage documentation in script header
4. Use `set -e` for error handling
5. Make executable: `chmod +x script.sh`
6. Document in this README
7. Commit to Git

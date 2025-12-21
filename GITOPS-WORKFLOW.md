# GitOps Workflow - MANDATORY FOR ALL CHANGES

## CRITICAL RULE: Infrastructure as Code (IaC) ONLY

**ALWAYS follow this workflow. NO EXCEPTIONS.**

This repository uses GitOps principles. ALL infrastructure changes MUST be:
1. Defined in code (Terraform, Ansible, Kubernetes manifests)
2. Committed to git
3. Deployed via automation (Terraform, ArgoCD)

## Deployment Methods by Component

| Component | Tool | Workflow |
|-----------|------|----------|
| **Proxmox VMs/LXC** | Terraform | `terraform plan` → `terraform apply` |
| **VM Configuration** | Ansible | `ansible-playbook --check` → `ansible-playbook` |
| **Kubernetes Resources** | ArgoCD | Commit to git → ArgoCD auto-sync |
| **Secrets** | Infisical | Add to Infisical UI → InfisicalSecret CR in K8s |

## The ONLY Correct Workflow

### For Terraform (Proxmox VMs, Talos cluster)

```bash
cd /home/prod_homelab/infrastructure/terraform

# 1. Make changes to .tf files
vim main.tf

# 2. Commit to git FIRST
git add .
git commit -m "Description of change"
git push

# 3. Plan
terraform plan -out=prod.plan

# 4. Review plan output carefully

# 5. Apply
terraform apply prod.plan

# 6. Export kubeconfig if cluster changed
export KUBECONFIG=$(pwd)/generated/kubeconfig
```

### For Ansible (VM configuration)

```bash
cd /home/prod_homelab/infrastructure/ansible

# 1. Make changes to playbooks/roles
vim playbooks/plex-nvidia.yml

# 2. Commit to git FIRST
git add .
git commit -m "Description of change"
git push

# 3. Check mode (dry run)
ansible-playbook -i inventory/plex.yml playbooks/plex-nvidia.yml --check

# 4. Run playbook
ansible-playbook -i inventory/plex.yml playbooks/plex-nvidia.yml
```

### For Kubernetes (Applications, Platform)

```bash
cd /home/prod_homelab

# 1. Make changes to manifests
vim kubernetes/applications/apps/homepage/deployment.yaml

# 2. Commit to git FIRST (this is the deployment!)
git add .
git commit -m "Description of change"
git push

# 3. ArgoCD automatically syncs within 3 minutes
# OR force sync:
kubectl patch application homepage -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'

# 4. Verify
kubectl get pods -n homepage
```

### For Secrets

```bash
# 1. Add secret to Infisical UI
#    Project: prod_homelab (slug: prod-homelab-y-nij)
#    Environment: prod
#    Path: appropriate folder (/, /kubernetes, /backups, /media, /mcp-credentials)

# 2. Create InfisicalSecret CR manifest
vim kubernetes/applications/apps/<app>/infisical-secret.yaml

# 3. Commit to git
git add .
git commit -m "Add InfisicalSecret for <app>"
git push

# 4. ArgoCD auto-syncs
# Secret appears in K8s automatically

# 5. Verify
kubectl get infisicalsecret -n <namespace>
kubectl get secret <secret-name> -n <namespace>
```

## FORBIDDEN Actions

### ❌ NEVER DO THESE:

```bash
# WRONG: Manual kubectl apply
kubectl apply -f deployment.yaml

# WRONG: Manual kubectl edit
kubectl edit deployment homepage

# WRONG: Manual kubectl create
kubectl create secret generic my-secret

# WRONG: Direct terraform apply without git commit
terraform apply

# WRONG: Hardcoded secrets in manifests
echo "password: mypassword" > secret.yaml

# WRONG: Manual VM creation in Proxmox UI
# (Use Terraform instead)
```

### ✅ CORRECT Alternatives:

```bash
# RIGHT: Commit to git, let ArgoCD sync
git add . && git commit -m "Update deployment" && git push

# RIGHT: Update manifest in git
vim kubernetes/apps/homepage/deployment.yaml
git add . && git commit && git push

# RIGHT: Use InfisicalSecret CR
# Add to Infisical UI, create InfisicalSecret manifest, commit

# RIGHT: Commit terraform changes first
git add . && git commit && git push
terraform plan && terraform apply

# RIGHT: Update terraform config
vim infrastructure/terraform/main.tf
```

## Exception: Manual ConfigMaps for Sensitive Configs

**ONLY for files that cannot be in git** (kubeconfig, talosconfig):

```bash
# These are NOT committed to git (security)
kubectl create configmap kubeconfig-prod \
  --from-file=kubeconfig=/path/to/kubeconfig \
  -n <namespace>

kubectl create configmap talosconfig \
  --from-file=talosconfig=/path/to/talosconfig \
  -n <namespace>
```

**Document these in README.md** so they can be recreated.

## GitOps Principles

1. **Git is the source of truth**
   - All infrastructure defined in git
   - No manual changes outside git
   - Git history = audit trail

2. **Declarative configuration**
   - Define desired state, not steps
   - Tools reconcile actual state to desired state
   - Idempotent operations

3. **Automated deployment**
   - ArgoCD watches git repo
   - Automatically applies changes
   - Self-healing (reverts manual changes)

4. **No kubectl apply**
   - ArgoCD handles all K8s deployments
   - Manual kubectl only for debugging/verification
   - Read-only kubectl commands are fine

## Workflow Checklist

Before making ANY infrastructure change:

- [ ] Is the change defined in code? (Terraform/Ansible/K8s manifest)
- [ ] Have I committed to git?
- [ ] Have I pushed to GitHub?
- [ ] Am I using the correct tool? (Terraform/Ansible/ArgoCD)
- [ ] Am I avoiding manual kubectl apply?
- [ ] Are secrets in Infisical, not hardcoded?

If you answered NO to any question, STOP and follow the correct workflow.

## Emergency: Reverting Changes

```bash
# Kubernetes (via ArgoCD)
git revert <commit-hash>
git push
# ArgoCD auto-syncs the revert

# Terraform
git revert <commit-hash>
git push
terraform plan  # Verify revert
terraform apply

# Ansible
git revert <commit-hash>
git push
ansible-playbook ...  # Re-run with old config
```

## Why GitOps?

1. **Audit trail**: Every change tracked in git history
2. **Rollback**: Easy to revert via git
3. **Consistency**: Same process for all changes
4. **Collaboration**: Team can review changes via PRs
5. **Disaster recovery**: Entire infrastructure in git
6. **No drift**: ArgoCD enforces desired state

## References

- ArgoCD: Kubernetes deployment automation
- Terraform: Infrastructure provisioning
- Ansible: Configuration management
- Infisical: Secrets management
- Git: Source of truth

---

**Remember**: If it's not in git, it doesn't exist. If you didn't commit first, you did it wrong.

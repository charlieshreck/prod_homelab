# Infisical Secrets Status

**Last Updated**: 2025-12-08

## Project Configuration

- **Project Name**: prod_homelab
- **Project Slug**: prod-homelab-y-nij
- **Project ID**: 9383e039-68ca-4bab-bc3c-aa06fdb82627
- **Environment**: prod
- **Service Token**: st.a46273f4-351c-4f5e-8de3-1e5f40391ffe... (use this one!)

## Current Secrets Status

### ✅ Path: `/infrastructure` (3 secrets)

| Secret Key | Status | Value Preview |
|------------|--------|---------------|
| GIT_HUB_PAT | ✅ Configured | ghp_Wd1y... |
| GITHUB_URL | ✅ Configured | https://github.com/charlieshreck/prod_homelab.git |
| proxmox_ssh_key | ✅ Configured | ssh-ed25519 AAAAC3Nz... |

### ❌ Path: `/` (Root - 0 secrets)

**Required but MISSING:**

| Secret Key | Purpose |
|------------|---------|
| CLOUDFLARE_API_TOKEN | Cloudflare DNS management for cert-manager |
| CLOUDFLARE_EMAIL | charlieshreck@gmail.com |
| CLOUDFLARE_ACCOUNT_ID | From Cloudflare dashboard |
| CLOUDFLARE_TUNNEL_NAME | homelab-kernow-io |

### ❌ Path: `/kubernetes` (0 secrets)

**Required but MISSING:**

| Secret Key | Purpose |
|------------|---------|
| CLOUDFLARE_TUNNEL_TOKEN | Token from Cloudflare tunnel creation |

### ❌ Path: `/backups` (0 secrets)

**Required but MISSING:**

| Secret Key | Purpose |
|------------|---------|
| RESTIC_PASSWORD | Restic backup encryption password |
| MINIO_ACCESS_KEY | MinIO/S3 access key |
| MINIO_SECRET_KEY | MinIO/S3 secret key |

### ❌ Path: `/media` (0 secrets)

**Required but MISSING:**

| Secret Key | Purpose |
|------------|---------|
| PLEX_CLAIM_TOKEN | Get from https://plex.tv/claim (expires in 4 min!) |
| TRANSMISSION_USER | Transmission BitTorrent username |
| TRANSMISSION_PASS | Transmission BitTorrent password |

## Additional Infrastructure Secrets Needed

While you have some infrastructure secrets, you're still missing:

| Secret Key | Purpose | Current Status |
|------------|---------|----------------|
| DOCKERHUB_USERNAME | Should be: mrlong67 | ❌ Missing |
| DOCKERHUB_PASSWORD | Docker Hub access token | ❌ Missing |

## What to Do Next

### 1. Add Root-Level Secrets (`/`)

In Infisical UI:
1. Select **prod** environment
2. Make sure you're at the **root level** (not in any folder)
3. Click **Add Secret** for each:
   - CLOUDFLARE_API_TOKEN
   - CLOUDFLARE_EMAIL = `charlieshreck@gmail.com`
   - CLOUDFLARE_ACCOUNT_ID
   - CLOUDFLARE_TUNNEL_NAME = `homelab-kernow-io`

### 2. Create Folders and Add Secrets

Create each folder and add secrets:

**Folder: `kubernetes`**
- CLOUDFLARE_TUNNEL_TOKEN

**Folder: `backups`**
- RESTIC_PASSWORD (generate strong password)
- MINIO_ACCESS_KEY
- MINIO_SECRET_KEY

**Folder: `media`**
- PLEX_CLAIM_TOKEN (get fresh from https://plex.tv/claim)
- TRANSMISSION_USER
- TRANSMISSION_PASS

### 3. Add Missing Infrastructure Secrets

In the **existing** `infrastructure` folder, add:
- DOCKERHUB_USERNAME = `mrlong67`
- DOCKERHUB_PASSWORD

## Verification

After adding secrets, verify with:

```bash
export INFISICAL_SERVICE_TOKEN="st.a46273f4-351c-4f5e-8de3-1e5f40391ffe.31920c113fa1e30fe99d6600ce7d77f5.15ecd6e9e8a199249b850c5b14e809df"
./scripts/verify-infisical-secrets.sh
```

## Critical Notes

1. **PLEX_CLAIM_TOKEN**: Get this RIGHT BEFORE deployment - it expires in 4 minutes!
2. **Cloudflare Setup**: You'll need to:
   - Create Cloudflare API token with DNS edit permissions
   - Create Cloudflare Tunnel named `homelab-kernow-io`
   - Get tunnel token from tunnel creation
3. **GitHub URL**: Currently points to `prod_homelab` repo - correct for this project

## Using Secrets in Terraform

Update your `terraform.tfvars` with:

```hcl
# Infisical Configuration
infisical_project_id   = "9383e039-68ca-4bab-bc3c-aa06fdb82627"
infisical_project_slug = "prod-homelab-y-nij"
infisical_env_slug     = "prod"

# For Kubernetes Universal Auth (create Machine Identity in Infisical)
infisical_client_id     = "<from-machine-identity>"
infisical_client_secret = "<from-machine-identity>"
```

## Using Secrets in Kubernetes

All InfisicalSecret manifests must use:

```yaml
spec:
  authentication:
    universalAuth:
      secretsScope:
        projectSlug: prod-homelab-y-nij  # Project slug, not ID!
        envSlug: prod
        secretsPath: /path  # e.g., /, /infrastructure, /kubernetes
```

**Note**: Kubernetes manifests use `projectSlug`, but the REST API uses `workspaceId` (the UUID).

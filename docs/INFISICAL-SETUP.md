# Infisical Secrets Setup

## Project Information
- **Project Name**: prod_homelab
- **Project Slug**: prod-homelab-y-nij
- **Environment**: prod
- **URL**: https://app.infisical.com

## Service Token
```
st.29141f37-bb1a-4ad9-abe8-4654088fce3d.732d34b6a7b5fe7467abcc63abe588c3.67e7e3062068e2e6cd2fcd4510
```

## Required Secrets

### Path: `/` (Root Level)
Navigate to: Project → Secrets → prod environment → root path

| Secret Key | Example/Notes |
|------------|---------------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token with DNS edit permissions |
| `CLOUDFLARE_EMAIL` | `charlieshreck@gmail.com` |
| `CLOUDFLARE_ACCOUNT_ID` | From Cloudflare dashboard |
| `CLOUDFLARE_TUNNEL_NAME` | `homelab-kernow-io` |

### Path: `/kubernetes`
Navigate to: Project → Secrets → prod environment → Create folder "kubernetes"

| Secret Key | Example/Notes |
|------------|---------------|
| `CLOUDFLARE_TUNNEL_TOKEN` | Token from Cloudflare tunnel creation |

### Path: `/backups`
Navigate to: Project → Secrets → prod environment → Create folder "backups"

| Secret Key | Example/Notes |
|------------|---------------|
| `RESTIC_PASSWORD` | Strong password for Restic encryption |
| `MINIO_ACCESS_KEY` | MinIO/S3 access key for backup storage |
| `MINIO_SECRET_KEY` | MinIO/S3 secret key |

### Path: `/media`
Navigate to: Project → Secrets → prod environment → Create folder "media"

| Secret Key | Example/Notes |
|------------|---------------|
| `PLEX_CLAIM_TOKEN` | Get fresh token from https://plex.tv/claim (expires in 4 min!) |
| `TRANSMISSION_USER` | Transmission username |
| `TRANSMISSION_PASS` | Transmission password |

### Path: `/infrastructure`
Navigate to: Project → Secrets → prod environment → Create folder "infrastructure"

| Secret Key | Example/Notes |
|------------|---------------|
| `DOCKERHUB_USERNAME` | `mrlong67` |
| `DOCKERHUB_PASSWORD` | Docker Hub access token |
| `GITHUB_PAT` | GitHub Personal Access Token for pulling private repos |

## How to Add Secrets in Infisical UI

1. Go to https://app.infisical.com
2. Select project: **prod_homelab**
3. Click on **Secrets** in sidebar
4. Select environment: **prod**
5. For root-level secrets (`/`):
   - Click **Add Secret**
   - Enter key and value
   - Click **Save**
6. For folder-level secrets (e.g., `/kubernetes`):
   - Click **Create Folder** button
   - Name it (e.g., "kubernetes")
   - Click into the folder
   - Click **Add Secret**
   - Enter key and value
   - Click **Save**

## Verification

After adding all secrets, run:

```bash
export INFISICAL_SERVICE_TOKEN="st.29141f37-bb1a-4ad9-abe8-4654088fce3d.732d34b6a7b5fe7467abcc63abe588c3.67e7e3062068e2e6cd2fcd5e4cdd4510"
./scripts/verify-infisical-secrets.sh
```

Expected output should show ✅ for all required secrets.

## Usage in Terraform

The Infisical secrets will be synced to Kubernetes via the Infisical Operator. Terraform needs to create the Universal Auth credentials:

```hcl
# In terraform.tfvars (DO NOT COMMIT)
infisical_project_slug = "prod-homelab-y-nij"
infisical_client_id    = "<from-infisical-machine-identity>"
infisical_client_secret = "<from-infisical-machine-identity>"
```

## Usage in Kubernetes

All secrets use the InfisicalSecret CRD:

```yaml
apiVersion: secrets.infisical.com/v1alpha1
kind: InfisicalSecret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
spec:
  hostAPI: https://app.infisical.com/api
  authentication:
    universalAuth:
      credentialsRef:
        secretName: universal-auth-credentials
        secretNamespace: infisical-operator-system
      secretsScope:
        projectSlug: prod-homelab-y-nij  # Must match exactly
        envSlug: prod
        secretsPath: /  # or /kubernetes, /media, etc.
  managedSecretReference:
    secretName: cloudflare-api-token
    secretNamespace: cert-manager
    secretType: Opaque
    creationPolicy: Owner
```

## Important Notes

1. **PLEX_CLAIM_TOKEN expires in 4 minutes** - Get it fresh from https://plex.tv/claim right before deployment
2. **Never commit service tokens** to Git
3. All Kubernetes secrets MUST come from Infisical - no hardcoded secrets in manifests
4. The project slug `prod-homelab-y-nij` must be used in all InfisicalSecret manifests
5. When updating secrets, the Infisical Operator will automatically sync them to Kubernetes (may take up to 60 seconds)

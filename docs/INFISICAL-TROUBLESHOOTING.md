# Infisical Troubleshooting

## Issue: Added Secrets Not Showing in API

If you've added secrets in the Infisical UI but they're not appearing when queried via API, check:

### 1. Verify Service Token Permissions

The service token must have **read access** to secrets. Check in Infisical UI:

1. Go to **Project Settings** → **Access Control** → **Service Tokens**
2. Find your service token (starts with `st.2914...`)
3. Verify it has:
   - ✅ **Read** permission (required)
   - Environment: **prod** (or the environment you're adding secrets to)
   - Scopes: Should include the paths you're adding secrets to

### 2. Verify Environment Name

Service tokens are scoped to specific environments. Our token should be for environment: **`prod`**

In the Infisical UI:
1. Click on the environment dropdown (top of the Secrets page)
2. Confirm you're viewing/editing the **prod** environment
3. If "prod" doesn't exist, you may need to create it or use "dev"

### 3. Verify Folder Structure

Secrets must be added to specific folder paths. In Infisical:

**For root-level secrets** (like CLOUDFLARE_API_TOKEN):
- Stay in the main secrets view (don't go into any folder)
- Click **Add Secret**
- Add your key/value pairs

**For folder-level secrets** (like `/infrastructure`):
- First, create the folder if it doesn't exist:
  - Click **Create Folder** button (or folder icon)
  - Name it exactly: `infrastructure` (no leading slash)
- Then click into that folder
- Click **Add Secret** inside the folder
- Add your key/value pairs

### 4. Check for Save/Sync Issues

After adding secrets:
- Ensure you clicked **Save** or **Create** button
- Wait a few seconds for sync
- Refresh the page to confirm secrets appear

### 5. Correct Folder Names

Folder names should NOT include leading slashes when creating in UI:
- ✅ Create folder named: `infrastructure`
- ✅ Create folder named: `kubernetes`
- ❌ NOT: `/infrastructure`
- ❌ NOT: `/kubernetes`

But when querying via API, use leading slash:
- API path: `/infrastructure`
- API path: `/kubernetes`

## Current Configuration

- **Project Name**: prod_homelab
- **Project Slug**: prod-homelab-y-nij
- **Environment**: prod
- **Service Token**: st.2914... (provided)

## Manual Check in UI

1. Go to https://app.infisical.com
2. Select project: **prod_homelab**
3. Ensure environment dropdown shows: **prod**
4. Look for folders named:
   - `infrastructure`
   - `kubernetes`
   - `backups`
   - `media`
5. Click into each folder and verify secrets exist

## Re-generate Service Token (If Needed)

If the token doesn't have proper permissions:

1. In Infisical project settings → **Service Tokens**
2. Delete old token
3. Create new token:
   - Name: `homelab-prod-access`
   - Environment: **prod**
   - Permissions: **Read & Write**
   - Expiration: Never (or set custom)
4. Copy new token and update in this repo

## Expected Folder Structure

```
prod_homelab (project)
└── prod (environment)
    ├── (root level)
    │   ├── CLOUDFLARE_API_TOKEN
    │   ├── CLOUDFLARE_EMAIL
    │   ├── CLOUDFLARE_ACCOUNT_ID
    │   └── CLOUDFLARE_TUNNEL_NAME
    ├── infrastructure/
    │   ├── GITHUB_PAT
    │   ├── GITHUB_URL
    │   ├── PROXMOX_SSH_KEY
    │   ├── DOCKERHUB_USERNAME
    │   └── DOCKERHUB_PASSWORD
    ├── kubernetes/
    │   └── CLOUDFLARE_TUNNEL_TOKEN
    ├── backups/
    │   ├── RESTIC_PASSWORD
    │   ├── MINIO_ACCESS_KEY
    │   └── MINIO_SECRET_KEY
    └── media/
        ├── PLEX_CLAIM_TOKEN
        ├── TRANSMISSION_USER
        └── TRANSMISSION_PASS
```

## Test API Access

```bash
# Test root path
curl -s -X GET \
  "https://app.infisical.com/api/v3/secrets/raw?workspaceSlug=prod-homelab-y-nij&environment=prod&secretPath=/" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Test infrastructure folder
curl -s -X GET \
  "https://app.infisical.com/api/v3/secrets/raw?workspaceSlug=prod-homelab-y-nij&environment=prod&secretPath=/infrastructure" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

Expected response when secrets exist:
```json
{
  "secrets": [
    {
      "secretKey": "GITHUB_PAT",
      "secretValue": "ghp_xxxxx...",
      ...
    }
  ],
  "imports": []
}
```

Expected response when no secrets (current):
```json
{
  "secrets": [],
  "imports": []
}
```

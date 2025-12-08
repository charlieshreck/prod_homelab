# Infisical Service Token Verification Steps

## Current Situation
- ✅ Secrets exist in UI (you can see them)
- ✅ Service token authenticates to API
- ❌ API returns empty secrets (permission issue)

## Please Check These in Infisical UI

### 1. Verify Service Token Permissions

Go to: **Project Settings** → **Service Tokens** (or **Access Control** → **Service Tokens**)

Find the token: `st.29141f37-bb1a-4ad9-abe8-4654088fce3d...`

Check these settings:
- [ ] **Environment**: Should be set to "Production" (or whichever environment has your secrets)
- [ ] **Permissions**: Should have **"Read"** checkbox enabled (or "Read & Write")
- [ ] **Secret Path**: Should be `/` (root) or empty to access all paths

### 2. Check Environment Slug Name

The environment might have a different internal slug than what's displayed.

In the Infisical UI:
1. Go to **Project Settings** → **Environments**
2. Look for your "Production" environment
3. There should be a **slug** field - what does it say?
   - It might be: `prod`, `production`, `Production`, or something else

### 3. Verify Folder Path Structure

In the Secrets view:
1. Ensure you're in the "Production" environment (check dropdown at top)
2. Do you see a folder icon labeled "infrastructure"?
3. When you click into that folder, what does the breadcrumb path show?
   - Should show something like: `Production / infrastructure`

### 4. Alternative: Create New Service Token

If the current token has permission issues, create a fresh one:

1. **Go to Project Settings** → **Service Tokens**
2. **Click "Create Token"** or "Add Service Token"
3. **Configure**:
   - Name: `homelab-prod-read`
   - Environment: **Production** (select from dropdown)
   - Expiration: **Never** (or custom date)
   - Secret Path: **/** (root - gives access to all paths)
   - Permissions: ✅ **Read** (check this box)
4. **Copy the new token** (starts with `st.`)
5. **Send me the new token** to test

## What to Report Back

Please provide:
1. **Environment slug** (from Project Settings → Environments)
2. **Service token permissions** (Read? Write? Environment?)
3. **Exact breadcrumb path** when viewing secrets (e.g., "Production / infrastructure" or something else?)
4. **New service token** if you created one

## Why This Matters

The Infisical API needs:
- Correct environment name (might be `Production`, `prod`, or something else)
- Correct secret path (might be `/infrastructure`, `/`, or nested differently)
- Service token with read permissions for that environment and path

Once we identify the correct values, we can update all the Kubernetes manifests to use the right configuration.

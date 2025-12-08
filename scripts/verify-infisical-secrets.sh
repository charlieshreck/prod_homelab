#!/bin/bash
# Verify Infisical secrets are configured
# Usage: ./verify-infisical-secrets.sh <service-token>

set -e

TOKEN="${1:-${INFISICAL_SERVICE_TOKEN}}"
if [ -z "$TOKEN" ]; then
    echo "Error: Service token required"
    echo "Usage: $0 <service-token>"
    echo "   or: export INFISICAL_SERVICE_TOKEN=<token> && $0"
    exit 1
fi

WORKSPACE_ID="9383e039-68ca-4bab-bc3c-aa06fdb82627"
ENV="prod"
API_BASE="https://app.infisical.com/api/v3/secrets/raw"

echo "=== Infisical Secrets Verification ==="
echo "Workspace ID: $WORKSPACE_ID"
echo "Environment: $ENV"
echo ""

check_path() {
    local path=$1
    local required_keys=$2

    echo "Checking path: $path"

    response=$(curl -s -X GET \
        "${API_BASE}?workspaceId=${WORKSPACE_ID}&environment=${ENV}&secretPath=${path}" \
        -H "Authorization: Bearer ${TOKEN}")

    # Extract secret keys (using grep/sed if jq not available)
    if command -v jq &> /dev/null; then
        keys=$(echo "$response" | jq -r '.secrets[]?.secretKey' 2>/dev/null)
    else
        keys=$(echo "$response" | grep -o '"secretKey":"[^"]*"' | sed 's/"secretKey":"//g' | sed 's/"//g')
    fi

    if [ -z "$keys" ]; then
        echo "  ❌ No secrets found"
        echo ""
        return 1
    fi

    echo "  Found secrets:"
    echo "$keys" | while read -r key; do
        echo "    ✅ $key"
    done

    # Check required keys
    for req_key in $required_keys; do
        if ! echo "$keys" | grep -q "^${req_key}$"; then
            echo "  ⚠️  Missing: $req_key"
        fi
    done

    echo ""
}

# Check root path
check_path "/" "CLOUDFLARE_API_TOKEN CLOUDFLARE_EMAIL CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_TUNNEL_NAME"

# Check /kubernetes
check_path "/kubernetes" "CLOUDFLARE_TUNNEL_TOKEN"

# Check /backups
check_path "/backups" "RESTIC_PASSWORD MINIO_ACCESS_KEY MINIO_SECRET_KEY"

# Check /media
check_path "/media" "PLEX_CLAIM_TOKEN TRANSMISSION_USER TRANSMISSION_PASS"

# Check /infrastructure
check_path "/infrastructure" "DOCKERHUB_USERNAME DOCKERHUB_PASSWORD GITHUB_PAT"

echo "=== Verification Complete ==="

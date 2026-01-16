#!/bin/bash
# Test Infisical environment access
# Usage: INFISICAL_TOKEN=<token> ./test-infisical-envs.sh
#
# NOTE: Never hardcode tokens in scripts. Use environment variables or Infisical CLI.

set -euo pipefail

if [[ -z "${INFISICAL_TOKEN:-}" ]]; then
    echo "Error: INFISICAL_TOKEN environment variable not set"
    echo "Usage: INFISICAL_TOKEN=<token> $0"
    exit 1
fi

PROJECT_ID="${INFISICAL_PROJECT_ID:-9383e039-68ca-4bab-bc3c-aa06fdb82627}"

for env in dev staging prod; do
    echo "=== Testing: $env ==="
    response=$(curl -s -X GET \
        "https://app.infisical.com/api/v3/secrets/raw?workspaceId=${PROJECT_ID}&environment=${env}&secretPath=/" \
        -H "Authorization: Bearer ${INFISICAL_TOKEN}" 2>&1)

    # Check if response contains secrets (don't print values)
    if echo "$response" | grep -q '"secrets"'; then
        secret_count=$(echo "$response" | grep -o '"secretKey"' | wc -l)
        echo "  Found $secret_count secrets"
    else
        echo "  No access or error"
    fi
    echo ""
done

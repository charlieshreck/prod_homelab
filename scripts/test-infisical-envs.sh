#!/bin/bash
TOKEN="st.580273bd-df0a-4530-ac87-3b43e2740c2f.21f36ada3c46fbe4f5c513c5fd3f2f2e.01ce3e0b7b085acfea804afc1325b45b"
PROJECT_ID="9383e039-68ca-4bab-bc3c-aa06fdb82627"

for env in dev development staging test production prod Production PROD; do
    echo "=== Testing: $env ==="
    curl -s -X GET \
        "https://app.infisical.com/api/v3/secrets/raw?workspaceId=${PROJECT_ID}&environment=${env}&secretPath=/" \
        -H "Authorization: Bearer ${TOKEN}" | head -c 300
    echo ""
    echo ""
done

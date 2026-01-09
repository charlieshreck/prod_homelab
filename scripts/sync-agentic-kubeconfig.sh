#!/bin/bash
# Sync Homepage agentic cluster credentials
#
# This script extracts the service account token and CA certificate from the
# agentic Talos cluster and creates/updates the secret in the production
# cluster so Homepage can display all three clusters.
#
# Prerequisites:
# - Agentic cluster kubeconfig at /home/agentic_lab/infrastructure/terraform/talos-cluster/generated/kubeconfig
# - Production cluster kubeconfig at /home/prod_homelab/infrastructure/terraform/generated/kubeconfig
# - Homepage service account must exist in agentic cluster (deployed via ArgoCD)
#
# Usage: ./scripts/sync-agentic-kubeconfig.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Syncing Homepage Agentic Cluster Credentials ===${NC}"

# Configuration
AGENTIC_KUBECONFIG="/home/agentic_lab/infrastructure/terraform/talos-cluster/generated/kubeconfig"
PROD_KUBECONFIG="/home/prod_homelab/infrastructure/terraform/generated/kubeconfig"
SERVICE_ACCOUNT="homepage"
NAMESPACE="homepage"
SECRET_NAME="homepage-agentic-kubeconfig"
SECRET_NAMESPACE="apps"
TOKEN_DURATION="876000h"  # 100 years

# Temporary files
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

TOKEN_FILE="${TEMP_DIR}/token"
CA_FILE="${TEMP_DIR}/ca.crt"

# Validate kubeconfig files exist
if [[ ! -f "${AGENTIC_KUBECONFIG}" ]]; then
    echo -e "${RED}✗ Agentic kubeconfig not found: ${AGENTIC_KUBECONFIG}${NC}"
    exit 1
fi

if [[ ! -f "${PROD_KUBECONFIG}" ]]; then
    echo -e "${RED}✗ Production kubeconfig not found: ${PROD_KUBECONFIG}${NC}"
    exit 1
fi

echo -e "${YELLOW}→ Checking agentic cluster connectivity...${NC}"
if ! kubectl --kubeconfig="${AGENTIC_KUBECONFIG}" cluster-info &>/dev/null; then
    echo -e "${RED}✗ Cannot connect to agentic cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to agentic cluster${NC}"

echo -e "${YELLOW}→ Checking production cluster connectivity...${NC}"
if ! kubectl --kubeconfig="${PROD_KUBECONFIG}" cluster-info &>/dev/null; then
    echo -e "${RED}✗ Cannot connect to production cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to production cluster${NC}"

echo -e "${YELLOW}→ Verifying Homepage service account exists in agentic cluster...${NC}"
if ! kubectl --kubeconfig="${AGENTIC_KUBECONFIG}" get serviceaccount "${SERVICE_ACCOUNT}" -n "${NAMESPACE}" &>/dev/null; then
    echo -e "${RED}✗ Service account ${SERVICE_ACCOUNT} not found in namespace ${NAMESPACE}${NC}"
    echo -e "${YELLOW}  Ensure the homepage-rbac-agentic ArgoCD application is synced first${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Service account exists${NC}"

echo -e "${YELLOW}→ Generating fresh service account token...${NC}"
kubectl --kubeconfig="${AGENTIC_KUBECONFIG}" create token "${SERVICE_ACCOUNT}" \
    -n "${NAMESPACE}" \
    --duration="${TOKEN_DURATION}" > "${TOKEN_FILE}"

if [[ ! -s "${TOKEN_FILE}" ]]; then
    echo -e "${RED}✗ Failed to generate token${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Token generated (valid for ${TOKEN_DURATION})${NC}"

echo -e "${YELLOW}→ Extracting CA certificate from agentic cluster...${NC}"
kubectl --kubeconfig="${AGENTIC_KUBECONFIG}" config view --raw \
    -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "${CA_FILE}"

if [[ ! -s "${CA_FILE}" ]]; then
    echo -e "${RED}✗ Failed to extract CA certificate${NC}"
    exit 1
fi
echo -e "${GREEN}✓ CA certificate extracted${NC}"

echo -e "${YELLOW}→ Verifying credentials work...${NC}"
AGENTIC_SERVER=$(kubectl --kubeconfig="${AGENTIC_KUBECONFIG}" config view --raw -o jsonpath='{.clusters[0].cluster.server}')
if ! kubectl --server="${AGENTIC_SERVER}" \
    --token="$(cat ${TOKEN_FILE})" \
    --certificate-authority="${CA_FILE}" \
    get nodes &>/dev/null; then
    echo -e "${RED}✗ Credentials verification failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Credentials verified successfully${NC}"

echo -e "${YELLOW}→ Creating/updating secret in production cluster...${NC}"
if kubectl --kubeconfig="${PROD_KUBECONFIG}" get secret "${SECRET_NAME}" -n "${SECRET_NAMESPACE}" &>/dev/null; then
    echo -e "${YELLOW}  Secret exists, deleting...${NC}"
    kubectl --kubeconfig="${PROD_KUBECONFIG}" delete secret "${SECRET_NAME}" -n "${SECRET_NAMESPACE}"
fi

kubectl --kubeconfig="${PROD_KUBECONFIG}" create secret generic "${SECRET_NAME}" \
    --from-file=ca="${CA_FILE}" \
    --from-file=token="${TOKEN_FILE}" \
    --namespace="${SECRET_NAMESPACE}"

echo -e "${GREEN}✓ Secret created/updated${NC}"

echo -e "${YELLOW}→ Restarting Homepage deployment...${NC}"
kubectl --kubeconfig="${PROD_KUBECONFIG}" rollout restart deployment homepage -n "${SECRET_NAMESPACE}"
kubectl --kubeconfig="${PROD_KUBECONFIG}" rollout status deployment homepage -n "${SECRET_NAMESPACE}" --timeout=60s

echo -e "${GREEN}✓ Homepage restarted successfully${NC}"

echo ""
echo -e "${GREEN}=== Sync Complete ===${NC}"
echo -e "Homepage can now access all three clusters:"
echo -e "  • Production: https://10.10.0.40:6443 (4 nodes)"
echo -e "  • Monitoring: https://10.30.0.20:6443 (1 node)"
echo -e "  • Agentic:    https://10.20.0.40:6443 (1 node)"
echo ""
echo -e "${YELLOW}Note: Token expires in ${TOKEN_DURATION} ($(date -d "+100 years" +"%Y-%m-%d"))${NC}"

#!/bin/bash
# Sync Homepage monitoring cluster credentials
#
# This script extracts the service account token and CA certificate from the
# monitoring Talos cluster and creates/updates the secret in the production
# cluster so Homepage can display both clusters.
#
# Prerequisites:
# - Unified kubeconfig at /root/.kube/config with contexts for all clusters
# - Homepage service account must exist in monitoring cluster (deployed via ArgoCD)
#
# Usage: ./scripts/sync-monitoring-kubeconfig.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Syncing Homepage Monitoring Cluster Credentials ===${NC}"

# Configuration
KUBECONFIG="/root/.kube/config"
MONITORING_CONTEXT="admin@monitoring-cluster"
PROD_CONTEXT="admin@homelab-prod"
SERVICE_ACCOUNT="homepage"
NAMESPACE="homepage"
SECRET_NAME="homepage-monitoring-kubeconfig"
SECRET_NAMESPACE="apps"
TOKEN_DURATION="876000h"  # 100 years

# Temporary files
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

TOKEN_FILE="${TEMP_DIR}/token"
CA_FILE="${TEMP_DIR}/ca.crt"

# Validate kubeconfig exists
if [[ ! -f "${KUBECONFIG}" ]]; then
    echo -e "${RED}✗ Kubeconfig not found: ${KUBECONFIG}${NC}"
    exit 1
fi
export KUBECONFIG

echo -e "${YELLOW}→ Checking monitoring cluster connectivity...${NC}"
if ! kubectl --context="${MONITORING_CONTEXT}" cluster-info &>/dev/null; then
    echo -e "${RED}✗ Cannot connect to monitoring cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to monitoring cluster${NC}"

echo -e "${YELLOW}→ Checking production cluster connectivity...${NC}"
if ! kubectl --context="${PROD_CONTEXT}" cluster-info &>/dev/null; then
    echo -e "${RED}✗ Cannot connect to production cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to production cluster${NC}"

echo -e "${YELLOW}→ Verifying Homepage service account exists in monitoring cluster...${NC}"
if ! kubectl --context="${MONITORING_CONTEXT}" get serviceaccount "${SERVICE_ACCOUNT}" -n "${NAMESPACE}" &>/dev/null; then
    echo -e "${RED}✗ Service account ${SERVICE_ACCOUNT} not found in namespace ${NAMESPACE}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Service account exists${NC}"

# Get the monitoring cluster API server URL for the token audience
MONITORING_SERVER=$(kubectl --context="${MONITORING_CONTEXT}" config view --raw -o jsonpath='{.clusters[?(@.name=="monitoring-cluster")].cluster.server}')
echo -e "${YELLOW}→ Monitoring API server: ${MONITORING_SERVER}${NC}"

echo -e "${YELLOW}→ Generating fresh service account token...${NC}"
kubectl --context="${MONITORING_CONTEXT}" create token "${SERVICE_ACCOUNT}" \
    -n "${NAMESPACE}" \
    --audience="${MONITORING_SERVER}" \
    --duration="${TOKEN_DURATION}" > "${TOKEN_FILE}"

if [[ ! -s "${TOKEN_FILE}" ]]; then
    echo -e "${RED}✗ Failed to generate token${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Token generated (valid for ${TOKEN_DURATION})${NC}"

echo -e "${YELLOW}→ Extracting CA certificate from monitoring cluster...${NC}"
kubectl --context="${MONITORING_CONTEXT}" get configmap -n kube-system kube-root-ca.crt \
    -o jsonpath='{.data.ca\.crt}' > "${CA_FILE}"

if [[ ! -s "${CA_FILE}" ]]; then
    echo -e "${RED}✗ Failed to extract CA certificate${NC}"
    exit 1
fi
echo -e "${GREEN}✓ CA certificate extracted${NC}"

echo -e "${YELLOW}→ Verifying credentials work...${NC}"
if ! kubectl --server="${MONITORING_SERVER}" \
    --token="$(cat ${TOKEN_FILE})" \
    --certificate-authority="${CA_FILE}" \
    get nodes &>/dev/null; then
    echo -e "${RED}✗ Credentials verification failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Credentials verified successfully${NC}"

echo -e "${YELLOW}→ Creating/updating secret in production cluster...${NC}"
if kubectl --context="${PROD_CONTEXT}" get secret "${SECRET_NAME}" -n "${SECRET_NAMESPACE}" &>/dev/null; then
    echo -e "${YELLOW}  Secret exists, deleting...${NC}"
    kubectl --context="${PROD_CONTEXT}" delete secret "${SECRET_NAME}" -n "${SECRET_NAMESPACE}"
fi

kubectl --context="${PROD_CONTEXT}" create secret generic "${SECRET_NAME}" \
    --from-file=ca="${CA_FILE}" \
    --from-file=token="${TOKEN_FILE}" \
    --namespace="${SECRET_NAMESPACE}"

echo -e "${GREEN}✓ Secret created/updated${NC}"

echo -e "${YELLOW}→ Restarting Homepage deployment...${NC}"
kubectl --context="${PROD_CONTEXT}" rollout restart deployment homepage -n "${SECRET_NAMESPACE}"
kubectl --context="${PROD_CONTEXT}" rollout status deployment homepage -n "${SECRET_NAMESPACE}" --timeout=60s

echo -e "${GREEN}✓ Homepage restarted successfully${NC}"

echo ""
echo -e "${GREEN}=== Sync Complete ===${NC}"
echo -e "Homepage can now access both clusters:"
echo -e "  • Production: https://10.10.0.40:6443 (4 nodes)"
echo -e "  • Monitoring: ${MONITORING_SERVER} (1 node)"
echo ""
echo -e "${YELLOW}Note: Token expires in ${TOKEN_DURATION} ($(date -d "+100 years" +"%Y-%m-%d"))${NC}"

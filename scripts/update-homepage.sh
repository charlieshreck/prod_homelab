#!/bin/bash
# Script to apply homepage configuration changes and restart the deployment

set -e

KUBECONFIG="${KUBECONFIG:-/home/prod_homelab/infrastructure/terraform/generated/kubeconfig}"
export KUBECONFIG

echo "Applying homepage configuration..."
kubectl apply -f /home/prod_homelab/kubernetes/applications/apps/homepage/config.yaml

echo "Restarting homepage deployment..."
kubectl rollout restart deployment homepage -n apps

echo "Waiting for rollout to complete..."
kubectl rollout status deployment homepage -n apps

echo "✓ Homepage updated successfully!"

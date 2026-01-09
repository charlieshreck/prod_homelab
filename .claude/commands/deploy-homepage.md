Deploy Homepage changes by committing to git, pushing, syncing ArgoCD, and restarting the deployment.

Steps:
1. Commit any Homepage config changes with an appropriate message
2. Push to git
3. Sync the Homepage ArgoCD application
4. Restart the Homepage deployment and wait for rollout

Run these commands:
```bash
cd /home/prod_homelab && git add kubernetes/applications/apps/homepage/ && git commit -m "Update Homepage configuration" && git push
```

Then sync ArgoCD and restart:
```bash
KUBECONFIG=/home/prod_homelab/infrastructure/terraform/generated/kubeconfig kubectl patch application homepage -n argocd --type merge -p '{"operation":{"sync":{"prune":true}}}' && sleep 5 && KUBECONFIG=/home/prod_homelab/infrastructure/terraform/generated/kubeconfig kubectl rollout restart deployment homepage -n apps && KUBECONFIG=/home/prod_homelab/infrastructure/terraform/generated/kubeconfig kubectl rollout status deployment homepage -n apps --timeout=60s
```

Report the result to the user.

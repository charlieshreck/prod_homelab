Restart the Homepage deployment in the prod cluster to pick up configuration changes.

Run this command:
```bash
KUBECONFIG=/home/prod_homelab/infrastructure/terraform/generated/kubeconfig kubectl rollout restart deployment homepage -n apps && KUBECONFIG=/home/prod_homelab/infrastructure/terraform/generated/kubeconfig kubectl rollout status deployment homepage -n apps --timeout=60s
```

Report the result to the user.

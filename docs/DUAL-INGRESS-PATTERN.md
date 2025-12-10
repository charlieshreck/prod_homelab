# Dual-Ingress Pattern for Internal and External Access

## Overview

All applications in this homelab use a **dual-ingress pattern** to provide both internal (LAN) and external (internet) access to services. This pattern ensures:
- **Internal users** access services directly via Traefik LoadBalancer (fast, no internet round-trip)
- **External users** access services via Cloudflare Tunnel (secure, authenticated)

## Architecture

### Internal Access Flow
```
User (LAN) → Unbound DNS (*.kernow.io → 10.10.0.90)
→ Traefik LoadBalancer (10.10.0.90)
→ Service
```

### External Access Flow
```
User (Internet) → Cloudflare DNS (*.kernow.io → CNAME to tunnel)
→ Cloudflare Tunnel
→ Service
```

## Prerequisites

1. **Unbound DNS Configuration**
   - Wildcard A record: `*.kernow.io` → `10.10.0.90` (Traefik LoadBalancer IP)
   - This ensures internal clients resolve to Traefik instead of Cloudflare

2. **Traefik LoadBalancer**
   - Service: `traefik` in namespace `traefik`
   - LoadBalancer IP: `10.10.0.90` (assigned by MetalLB)

3. **Cloudflare Tunnel**
   - Tunnel ID: `c1773e37-276a-4076-b3bb-043aec7975db`
   - Running in namespace: `cloudflared`

4. **Cloudflare Tunnel Controller**
   - Running in namespace: `cloudflare-tunnel-controller`
   - Watches ingresses with `ingressClassName: cloudflare-tunnel`
   - Automatically creates DNS CNAME records
   - Automatically configures tunnel routes

## Creating a New Application with Dual Access

For every new application, you **MUST create TWO ingress resources**:

### 1. Traefik Ingress (Internal Access)

**File:** `kubernetes/applications/<namespace>/<app>/ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <app-name>
  namespace: <namespace>
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    # Add homepage annotations if needed
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - <app-name>.kernow.io
      secretName: <app-name>-tls
  rules:
    - host: <app-name>.kernow.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <service-name>
                port:
                  number: <port>
```

### 2. Cloudflare Tunnel Ingress (External Access)

**File:** `kubernetes/applications/<namespace>/<app>/cloudflare-tunnel-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <app-name>-cloudflare
  namespace: <namespace>
  labels:
    app: <app-name>
spec:
  ingressClassName: cloudflare-tunnel
  rules:
    - host: <app-name>.kernow.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <service-name>
                port:
                  number: <port>
```

**Key Differences:**
- Traefik ingress has TLS configuration (cert-manager manages certificates)
- Cloudflare-tunnel ingress does NOT need TLS config (Cloudflare handles SSL)
- Cloudflare-tunnel ingress name MUST end with `-cloudflare` suffix
- Both ingresses point to the SAME service and port
- Both ingresses use the SAME hostname

## Automatic Setup

When you create a cloudflare-tunnel ingress, the cloudflare-tunnel-controller will automatically:

1. **Create DNS Record**: CNAME record pointing `<app-name>.kernow.io` to the tunnel endpoint
2. **Configure Tunnel Route**: Add route in Cloudflare Tunnel to forward traffic to the service
3. **Update Ingress Status**: Add the tunnel hostname to the ingress status

You can verify by checking controller logs:
```bash
kubectl logs -n cloudflare-tunnel-controller \
  deployment/cloudflare-tunnel-controller-cloudflare-tunnel-ingress-controll \
  | grep "create DNS record"
```

## Example: Adding a New App

Let's say you're deploying a new app called `nextcloud`:

1. **Create the service and deployment** as usual

2. **Create Traefik ingress**: `kubernetes/applications/apps/nextcloud/ingress.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nextcloud
  namespace: apps
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - nextcloud.kernow.io
      secretName: nextcloud-tls
  rules:
    - host: nextcloud.kernow.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nextcloud
                port:
                  number: 80
```

3. **Create Cloudflare tunnel ingress**: `kubernetes/applications/apps/nextcloud/cloudflare-tunnel-ingress.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nextcloud-cloudflare
  namespace: apps
  labels:
    app: nextcloud
spec:
  ingressClassName: cloudflare-tunnel
  rules:
    - host: nextcloud.kernow.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nextcloud
                port:
                  number: 80
```

4. **Commit and push** - ArgoCD will deploy both ingresses

5. **Verify**:
   - Internal access: `https://nextcloud.kernow.io` (from LAN, goes to Traefik)
   - External access: `https://nextcloud.kernow.io` (from internet, goes through tunnel)

## Verification

### Check Ingresses
```bash
# Should see both ingresses for each app
kubectl get ingress -n apps
kubectl get ingress -n media

# Traefik ingress should have ADDRESS: 10.10.0.90
# Cloudflare ingress should have ADDRESS: <tunnel-endpoint>.cfargotunnel.com
```

### Check DNS Records
```bash
# Check controller created DNS record
kubectl logs -n cloudflare-tunnel-controller \
  deployment/cloudflare-tunnel-controller-cloudflare-tunnel-ingress-controll \
  --tail=100 | grep "DNS record"
```

### Check Tunnel Routes
```bash
# Check cloudflared received tunnel configuration
kubectl logs -n cloudflared deployment/cloudflared --tail=100 | grep "Updated to new configuration"
```

### Test Access
```bash
# From internal network (should resolve to 10.10.0.90)
dig <app-name>.kernow.io

# From external network (should resolve to Cloudflare CNAME)
dig <app-name>.kernow.io @8.8.8.8
```

## Troubleshooting

### App not accessible externally

1. Check cloudflare-tunnel ingress exists:
   ```bash
   kubectl get ingress <app-name>-cloudflare -n <namespace>
   ```

2. Check DNS record was created:
   ```bash
   kubectl logs -n cloudflare-tunnel-controller \
     deployment/cloudflare-tunnel-controller-cloudflare-tunnel-ingress-controll \
     | grep "<app-name>"
   ```

3. Check tunnel configuration:
   ```bash
   kubectl logs -n cloudflared deployment/cloudflared | grep "<app-name>"
   ```

### App not accessible internally

1. Check traefik ingress exists:
   ```bash
   kubectl get ingress <app-name> -n <namespace>
   ```

2. Check Traefik LoadBalancer is running:
   ```bash
   kubectl get svc traefik -n traefik
   # Should show EXTERNAL-IP: 10.10.0.90
   ```

3. Check Unbound DNS override is configured:
   ```
   *.kernow.io → 10.10.0.90
   ```

## Important Notes

- **NEVER** use only one ingress type - always create both
- **ALWAYS** use the same hostname for both ingresses
- **ALWAYS** use the `-cloudflare` suffix for tunnel ingress names
- The cloudflare-tunnel ingress does **NOT** need TLS configuration
- The traefik ingress **MUST** have TLS configuration for cert-manager
- DNS propagation can take a few minutes after creating a cloudflare-tunnel ingress

## Current Applications Using This Pattern

### Apps Namespace
- filebrowser (files.kernow.io)
- homeassistant (homeassistant.kernow.io)
- homepage (homepage.kernow.io)
- karakeep (karakeep.kernow.io)
- tasmoadmin (tasmoadmin.kernow.io)
- vaultwarden (vaultwarden.kernow.io)

### Media Namespace
- cleanuparr (cleanuparr.kernow.io)
- overseerr (overseerr.kernow.io)
- prowlarr (prowlarr.kernow.io)
- radarr (radarr.kernow.io)
- sabnzbd (sabnzbd.kernow.io)
- sonarr (sonarr.kernow.io)
- tautulli (tautulli.kernow.io)
- transmission (transmission.kernow.io)

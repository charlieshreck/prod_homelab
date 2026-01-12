# Configarr - TRaSH Guides Sync

Automated synchronization of [TRaSH Guides](https://trash-guides.info/) custom formats and quality profiles to Sonarr and Radarr.

## Overview

Configarr runs as a Kubernetes CronJob that:
- Clones TRaSH Guides and Recyclarr templates
- Syncs Custom Formats to Sonarr/Radarr
- Creates/updates Quality Profiles
- Updates Quality Definitions

## Configuration

### Schedule
- **Cron**: `0 0 * * *` (Daily at midnight)
- Modify in `cronjob.yaml` if needed

### Synced Profiles

| App | Profiles |
|-----|----------|
| Sonarr | WEB-1080p, WEB-2160p |
| Radarr | HD Bluray + WEB, UHD Bluray + WEB |

### Secrets

Uses existing InfisicalSecrets (no additional secrets needed):
- `sonarr-credentials` → `API_KEY`
- `radarr-credentials` → `API_KEY`

## Files

```
configarr/
├── configmap.yaml      # Configarr config.yml
├── cronjob.yaml        # CronJob definition
├── kustomization.yaml  # Kustomize resources
└── README.md           # This file
```

## Manual Operations

### Trigger Immediate Sync
```bash
kubectl create job --from=cronjob/configarr configarr-manual -n media
```

### Check Logs
```bash
kubectl logs -n media job/configarr-manual
```

### View CronJob Status
```bash
kubectl get cronjob configarr -n media
```

### Delete Failed Jobs
```bash
kubectl delete jobs -n media -l app=configarr --field-selector status.successful=0
```

## Customization

### Add Custom Formats

Edit `configmap.yaml` to add custom formats:

```yaml
custom_formats:
  - trash_ids:
      - abc123  # TRaSH Guide ID
    assign_scores_to:
      - name: WEB-1080p
        score: 100
```

### Change Schedule

Edit `cronjob.yaml`:
```yaml
spec:
  schedule: "0 */6 * * *"  # Every 6 hours
```

### Add More Profiles

Add templates to the `include` section in `configmap.yaml`:
```yaml
include:
  - template: sonarr-v4-quality-profile-anime
  - template: sonarr-v4-custom-formats-anime
```

## Troubleshooting

### Config File Not Found
- Ensure mount path is `/app/config/config.yml`
- Check ConfigMap is created: `kubectl get cm configarr-config -n media`

### Permission Denied (repos)
- Ensure emptyDir volume is mounted at `/app/repos`
- Check pod security context allows writing

### API Connection Failed
- Verify Sonarr/Radarr are running: `kubectl get pods -n media`
- Check API keys in secrets: `kubectl get secret sonarr-credentials -n media -o yaml`

## Links

- [Configarr Documentation](https://configarr.de)
- [TRaSH Guides](https://trash-guides.info/)
- [Recyclarr Templates](https://github.com/recyclarr/config-templates)

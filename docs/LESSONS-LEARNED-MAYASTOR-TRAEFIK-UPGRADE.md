# Lessons Learned: Mayastor 2.10.0 & Traefik v3.6 Upgrades

**Date**: 2026-03-13
**Impact**: 5+ hours recovery, full backup restore required across 20+ apps
**Risk Assessment (Pre-Upgrade)**: Low — routine version bumps
**Actual Outcome**: Critical — all persistent volume data lost, multi-hour incident

---

## What Happened

### Traefik Upgrade (v3.6.10)
- ArgoCD synced the new Traefik image across all three clusters
- Agentic cluster's Traefik began crash-looping: missing RBAC for `endpointslices` (required in v3.6+)
- Monitoring cluster's Traefik also affected (same manifest pattern)
- Prod cluster unaffected (Helm-managed with correct RBAC)

### Mayastor Upgrade (2.8.0 → 2.10.0)
- Mayastor etcd pre-upgrade hook could not schedule (anti-affinity on 3-node cluster)
- `SkipHooks=true` was added to ArgoCD sync options to bypass the hook
- The etcd StatefulSet was recreated with a new volume, **wiping the Mayastor metadata store**
- All 21 Mayastor PVs became orphaned — PVCs showed "Bound" but data was inaccessible
- Every app with a Mayastor volume lost its persistent data

---

## Root Cause Analysis

### Traefik
- **Cause**: Kubernetes API changed — `endpointslices` requires explicit RBAC in newer Traefik versions
- **Why it wasn't caught**: Manually-managed Traefik RBAC in agentic/monit clusters wasn't updated to match the image bump. Prod uses Helm which handles RBAC automatically.
- **Prevention**: Use Helm for all Traefik deployments, or have a pre-upgrade checklist that includes RBAC review.

### Mayastor
- **Cause**: ArgoCD's `SkipHooks=true` combined with etcd StatefulSet template drift caused a full etcd data wipe
- **Chain of events**:
  1. Helm rendered new etcd StatefulSet template (2.10.0)
  2. ArgoCD detected template drift and replaced the StatefulSet
  3. New etcd pod started with **empty** hostPath volume (new path hash)
  4. Mayastor control plane lost all volume metadata
  5. All PVs became orphaned — data on disk pools intact but unreferenceable
- **Why it wasn't caught**: The etcd StatefulSet was in `ignoreDifferences` for template drift, but `SkipHooks=true` removed the safety net of the pre-upgrade data migration hook
- **Prevention**: Never skip Mayastor Helm hooks without understanding their purpose. The etcd pre-upgrade hook exists specifically to migrate data safely.

---

## Recovery Process

### Duration: ~5 hours

1. **Identify data loss** (~30 min): Apps started with fresh/empty databases
2. **Locate backups** (~15 min): Velero weekly backup from March 8 (5 days old)
3. **First restore attempt** — PVCs only (~30 min): Created 0 PodVolumeRestores. Velero Kopia file-level restore requires pods to inject init containers.
4. **Scale ArgoCD to 0** (~5 min): Required because ArgoCD self-heal kept reverting manual changes
5. **Delete existing deployments** (~10 min): Velero can't match PVBs to pods unless it creates them from scratch
6. **Second restore attempt** — deployments+pods without PVCs (~20 min): Created 0 PVRs. Velero needs PVCs included to match backup PodVolumeBackups.
7. **Third restore attempt** — full (deployments+pods+PVCs) (~20 min): Partially worked — some PVRs completed but most stuck at "Prepared" due to 15 stale backup helper pods consuming all Velero concurrency.
8. **Clean up stuck backup pods** (~15 min): Force-deleted 15 daily-backup helper pods that had been running for days
9. **Fourth restore attempt** — same spec with `existingResourcePolicy: update` (~30 min): Successfully restored 14 of 22 PVRs (key apps: HA 127MB, Sonarr 561MB, Tautulli 128MB)
10. **Fix remaining volumes** (~90 min):
    - Stale VolumeAttachments blocking new mounts — manual deletion
    - CSI staging path corruption on worker-03 — CSI node restart
    - Sonarr crash-loop — corrupted logs.db from version mismatch, deleted to fix
    - Maintainerr/Notifiarr — PVCs with stale CSI staging, recreated fresh
    - Filebrowser — persistent CSI transport error on worker-03, temporarily scheduled away
11. **Re-enable ArgoCD** (~10 min): Scaled application-controller back to 1, verified git sync

---

## What Went Wrong (Process Failures)

### 1. No Pre-Upgrade Testing
Both upgrades were treated as "routine bumps" with no staging environment or pre-flight checks. The Traefik RBAC change and the Mayastor etcd migration requirements were documented in release notes but not reviewed.

### 2. No Upgrade Runbook
There was no documented procedure for upgrading Mayastor specifically. The `SkipHooks=true` was added as a workaround without understanding its implications.

### 3. Velero Backup Gaps
- **Backup was 5 days old**: Weekly schedule meant up to 7 days of data loss
- **No backup verification**: No one had tested a Velero restore before this incident
- **Velero Kopia restore is complex**: Requires specific resource combinations (pods + PVCs), healthy node-agents, cleared VolumeAttachments, and no concurrent backup operations
- **No documentation**: The Velero restore process was not documented anywhere

### 4. ArgoCD Self-Heal Conflicts
ArgoCD's self-heal aggressively reverted manual changes needed during recovery. Had to scale the entire application-controller to 0, which stopped ALL syncing across all three clusters for hours.

### 5. CSI Staging Path Fragility
Mayastor CSI staging paths on kubelet nodes become stale after etcd wipes. The jbd2 journal entries can block all CSI operations on a node with no automated recovery.

---

## Action Items

### Immediate (This Week)

- [x] **Velero backup frequency**: Already daily (0 2 * * *) + weekly (0 3 * * 0) — no change needed. Issue was restore complexity, not backup frequency.
- [x] **Document Velero restore procedure**: Written as `velero-restore-procedure.md` runbook with full troubleshooting guide
- [ ] **Test Velero restore**: Schedule quarterly restore tests to verify backup integrity
- [x] **Fix worker-03 CSI**: Resolved by restarting io-engine + csi-node pods on worker-03. Root cause: stale NVMe-oF transport state after Mayastor etcd wipe. New volume attachments returned "transport error" until io-engine was restarted.

### Short-Term (This Month)

- [x] **Create upgrade runbooks**: Written `mayastor-upgrade.md` runbook with pre-upgrade checklist and rollback plan
- [x] **Pre-upgrade checklist**: Included in `mayastor-upgrade.md` — release notes review, backup verification, etcd snapshot, state documentation
- [x] **ArgoCD emergency pause**: Written `argocd-emergency-pause.md` — per-app pause (Option 1) and controller scale (Option 2)
- [ ] **Mayastor etcd backup**: Implement etcd snapshot backup before any Mayastor upgrades

### Long-Term

- [ ] **Staging environment**: Test upgrades in a throwaway environment before production
- [ ] **Mayastor etcd persistence**: Ensure etcd data survives StatefulSet recreation (dedicated PV or hostPath with fixed path)
- [ ] **Automated restore testing**: CronJob that periodically restores to a test namespace and validates data integrity

---

## Key Learnings

1. **"Low risk" upgrades can have catastrophic outcomes** when storage system metadata is involved. Any upgrade that touches Mayastor, etcd, or CSI should be treated as high-risk regardless of the version delta.

2. **Velero file-level restore (Kopia) is not straightforward**. It requires:
   - Pods + PVCs + PVs all included in the restore spec
   - `existingResourcePolicy: update` for existing resources
   - No concurrent backup operations consuming node-agent concurrency
   - Healthy node-agents on all nodes
   - Clean VolumeAttachments (no stale references)
   - Deployments deleted before restore so Velero can create them from scratch

3. **ArgoCD is both friend and foe during incidents**. Self-heal is great for normal operations but actively works against manual recovery. Need a documented "incident mode" procedure.

4. **Backups you don't test aren't backups**. The weekly Velero backup existed but no one had ever verified a restore would actually work. It did work — but only after discovering and solving 6 distinct failure modes.

5. **CSI storage drivers have hidden state** on kubelet nodes (staging paths, journal entries, NVMe-oF connections). This state can become stale and block operations with no automated recovery. **Fix**: Restart the io-engine DaemonSet pod and csi-node DaemonSet pod on the affected node to clear stale NVMe-oF transport state.

6. **Velero Kopia PVR references specific pod UIDs**. If you delete a pod during a restore, the PVR becomes orphaned and can't find the new pod (different UID). Must keep the original pod alive or create a fresh restore.

7. **WaitForFirstConsumer PVCs with `nodeName` pods**: Using `nodeName` bypasses the scheduler, so the PVC never gets the `volume.kubernetes.io/selected-node` annotation. Must add this annotation manually for provisioning to proceed.

---

## Timeline

| Time | Event |
|------|-------|
| T+0 | Mayastor 2.10.0 upgrade applied via ArgoCD |
| T+5m | etcd StatefulSet recreated, metadata wiped |
| T+10m | All apps with Mayastor PVCs start crash-looping |
| T+30m | Data loss confirmed, Velero backup identified |
| T+1h | First restore attempt (PVCs only) — fails |
| T+1.5h | ArgoCD controller scaled to 0 |
| T+2h | Second restore attempt — fails (no PVCs included) |
| T+2.5h | Third restore attempt — partial success, blocked by stale backup pods |
| T+3h | Backup pods cleaned up, fourth restore started |
| T+3.5h | 14/22 PVRs completed (HA, Sonarr, Tautulli, etc.) |
| T+4h | Individual volume fixes (VAs, CSI staging, Sonarr logs.db) |
| T+4.5h | ArgoCD re-enabled, git sync reconciliation |
| T+5h | All 21 apps running, ArgoCD synced and healthy |

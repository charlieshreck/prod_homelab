# Matter Bridge Setup Guide

This guide explains how to configure Matter bridge mode in Home Assistant to expose all your devices to Google Home via Matter protocol.

## Prerequisites

✅ Matter Server deployed and running: `ws://matter-server.apps.svc.cluster.local:5580/ws`
✅ Home Assistant running and accessible: https://homeassistant.kernow.io

## Step-by-Step Setup

### 1. Add Matter Integration (First Time Setup)

1. Open Home Assistant: **https://homeassistant.kernow.io**
2. Go to **Settings** → **Devices & Services**
3. Click **+ Add Integration** (bottom right)
4. Search for: **"Matter"** or **"Matter (BETA)"**
5. Click **Matter (BETA)** in the results
6. When prompted for the server URL, enter:
   ```
   ws://matter-server.apps.svc.cluster.local:5580/ws
   ```
7. Click **Submit**
8. Wait for the integration to connect (should show as "Connected")

### 2. Enable Matter Bridge Mode

After adding the integration, you need to enable bridge mode to expose HA devices to Google:

#### Method A: Via Integration Configuration (Recommended)

1. In **Settings** → **Devices & Services**
2. Find the **Matter** integration card
3. Click the **three dots (⋮)** in the top-right corner of the card
4. Select **"Configure"** or **"Options"**
5. Look for one of these options:
   - **"Enable Matter bridge"** - Toggle it ON
   - **"Expose entities"** - Select which entities to share
   - **"Bridge mode"** - Enable it
6. Select which domains to expose:
   - ✅ Lights
   - ✅ Switches
   - ✅ Climate (thermostats)
   - ✅ Locks
   - ✅ Covers (blinds, garage doors)
   - ✅ Fans
   - ✅ Sensors
   - ✅ Binary sensors
   - ✅ Media players
   - ✅ Cameras
   - ✅ Vacuums
   - ✅ Any other device types you want Google to control
7. Click **Save** or **Submit**

#### Method B: Via Individual Entity Exposure

If the integration doesn't show bridge settings:

1. Go to **Settings** → **Devices & Services** → **Entities**
2. Find an entity you want to expose (e.g., a light)
3. Click on the entity
4. Click the **Settings (gear icon)**
5. Look for **"Expose to"** or **"Expose via"** section
6. Enable **Matter** checkbox
7. Repeat for each entity you want to expose

#### Method C: Enable Experimental Features

If bridge options don't appear, enable experimental features:

1. Click your **Profile** (bottom left corner, your name/icon)
2. Scroll to **"Experimental features"** section
3. Enable **"Advanced Mode"**
4. Enable **"Matter bridge"** if available
5. Go back to **Settings** → **Devices & Services** → **Matter**
6. Look for new bridge configuration options

### 3. Verify Bridge is Active

1. In **Settings** → **Devices & Services** → **Matter**
2. Click on **"X devices"** or **"Devices"** link
3. You should see a device named:
   - **"Home Assistant Bridge"** or
   - **"Matter Bridge"** or
   - **"Python Matter Server"**
4. This device represents your HA instance as a Matter bridge
5. It should show how many entities are exposed

### 4. Commission Bridge to Google Home

Now that the bridge is active, add it to Google Home:

1. Open **Google Home app** on your phone
2. Ensure you're on the **same Wi-Fi network** as your Home Assistant server
3. Tap **+** (Add) → **Set up device**
4. Select **"New device"** or **"Works with Google"**
5. Look for:
   - **"Home Assistant"** or
   - **"Matter"** or
   - The bridge device broadcasting via mDNS
6. Follow the on-screen pairing instructions
7. You may need to scan a QR code or enter a pairing code
   - The pairing code can be found in:
     - Home Assistant → Settings → Devices & Services → Matter → Bridge device
     - Or in the Matter integration configuration

### 5. Verify Devices in Google Home

1. After pairing, Google Home should discover all exposed devices
2. They will appear in your Google Home app
3. You can now control them with:
   - **"Hey Google, turn on [device name]"**
   - Google Home app
   - Google Home routines and automations

## Troubleshooting

### Matter Integration Not Showing

**Problem:** Can't find Matter in the integrations list

**Solution:**
- Ensure you're running Home Assistant 2023.6 or newer
- Update to the latest version: Settings → System → Updates
- Matter may be listed as "Matter (BETA)"

### Can't Connect to Matter Server

**Problem:** Error connecting to `ws://matter-server.apps.svc.cluster.local:5580/ws`

**Solution:**
```bash
# Check Matter Server is running
kubectl get pods -n apps -l app=matter-server

# Check service exists
kubectl get svc matter-server -n apps

# Test connectivity from HA pod
kubectl exec -n apps deployment/homeassistant -- \
  nc -zv matter-server.apps.svc.cluster.local 5580
```

### Bridge Options Not Visible

**Problem:** No bridge configuration options in the Matter integration

**Solution:**
1. Enable Advanced Mode in your user profile
2. Check for experimental features related to Matter
3. Ensure Matter integration is fully loaded (restart HA if needed)
4. Try exposing entities manually (per-entity method above)

### Google Home Can't Find Bridge

**Problem:** Bridge not showing up in Google Home app

**Solution:**
1. Verify bridge is enabled in HA Matter integration
2. Check Matter Server logs:
   ```bash
   kubectl logs -n apps -l app=matter-server --tail=50
   ```
3. Ensure your phone and HA are on the same network (10.10.0.0/24)
4. The Matter Server needs hostNetwork (already configured) for mDNS
5. Restart the Matter Server pod:
   ```bash
   kubectl delete pod -n apps -l app=matter-server
   ```

### Devices Not Exposing

**Problem:** Bridge works but specific devices don't appear in Google Home

**Solution:**
1. Not all entity types are supported by Matter protocol
2. Check which domains are selected in bridge configuration
3. Some entities may need to be exposed individually
4. Check Home Assistant logs for Matter-related errors

## Current Deployment Status

**Matter Server:**
- Running on: talos-worker-03 (10.10.0.43)
- Service: `matter-server.apps.svc.cluster.local:5580`
- WebSocket: `ws://matter-server.apps.svc.cluster.local:5580/ws`

**Home Assistant:**
- URL: https://homeassistant.kernow.io
- Service: `homeassistant.apps.svc.cluster.local:8123`

**Verification Commands:**
```bash
# Check pods
kubectl get pods -n apps -l 'app in (matter-server,homeassistant)'

# Check Matter Server logs
kubectl logs -n apps -l app=matter-server --tail=50

# Check Home Assistant logs for Matter
kubectl logs -n apps -l app=homeassistant --tail=100 | grep -i matter

# Restart Matter Server
kubectl delete pod -n apps -l app=matter-server

# Restart Home Assistant
kubectl delete pod -n apps -l app=homeassistant
```

## References

- [Home Assistant Matter Integration Docs](https://www.home-assistant.io/integrations/matter/)
- [Matter Protocol Overview](https://csa-iot.org/all-solutions/matter/)
- [Python Matter Server](https://github.com/home-assistant-libs/python-matter-server)

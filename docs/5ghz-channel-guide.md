# 5GHz Channel Selection Guide

## Quick Reference

### Non-DFS Channels (Safe, More Congested)
```
Best for: Business/critical applications, VoIP, gaming
Channels: 36, 40, 44, 48, 149, 153, 157, 161, 165

80 MHz Wide Channels:
- Channel 36 (uses 36+40+44+48)
- Channel 149 (uses 149+153+157+161) [USA only]

160 MHz Wide Channels:
- Channel 36 (uses 36-64, but 52-64 is DFS!)
- Not recommended for non-DFS deployment
```

### DFS Channels (Clean, Requires Radar Detection)
```
Best for: Home use, maximum performance, low latency
Channels: 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144

80 MHz Wide Channels:
- Channel 52 (uses 52+56+60+64)
- Channel 100 (uses 100+104+108+112)
- Channel 116 (uses 116+120+124+128)
- Channel 132 (uses 132+136+140+144)

160 MHz Wide Channels:
- Channel 100 (uses 100-132) ← Best choice!
```

---

## Channel Selection Strategy

### Single AP Setup
```
1st Choice:  Auto DFS (let UniFi pick cleanest channel)
2nd Choice:  Channel 100 or 116 (80 MHz) - DFS
3rd Choice:  Channel 36 or 149 (80 MHz) - Non-DFS
```

### Multi-AP Setup (2-3 APs)
```
Residential (enable DFS):
  AP1: Channel 36  (no DFS, stable)
  AP2: Channel 100 (DFS, clean)
  AP3: Channel 132 (DFS, clean)

Business (avoid DFS):
  AP1: Channel 36
  AP2: Channel 149 (USA only)
  AP3: Reuse Channel 36 if far apart
```

### Dense Deployment (4+ APs)
```
Enable Auto Channel:
  - UniFi will manage channel assignments
  - Avoid manual channel planning
  - Let RF AI optimize
```

---

## DFS Decision Matrix

### ✅ Enable DFS When:
- Home environment (radar events rare)
- Neighbor WiFi networks are congested
- Maximum performance needed
- Brief disconnects (60 sec) are acceptable
- Indoor APs only (outdoor near airports = bad)

### ❌ Disable DFS When:
- Business/mission-critical WiFi
- Near airport, military base, or weather station
- VoIP/video conferencing (can't tolerate disruptions)
- Customer-facing WiFi (retail, hospitality)
- Outdoor APs

---

## Testing DFS Channels

### Initial Test (Recommended):
```
1. Enable DFS channels in UniFi
2. Set channel to Auto
3. Wait 24 hours for RF scan
4. Check which channel UniFi selected
5. Monitor for radar events (Settings → Alerts)
```

### Manual DFS Testing:
```
Day 1-7:   Test Channel 100 (most reliable DFS)
Day 8-14:  Test Channel 116
Day 15-21: Test Channel 52

If radar event occurs:
  - Check UniFi alerts for event log
  - Note time and channel
  - If >1 event per month: Switch to non-DFS
```

---

## Regional Differences

### USA (FCC):
- UNII-1: 36-48 (4 channels x 20 MHz)
- UNII-2A: 52-64 (DFS required)
- UNII-2C: 100-144 (DFS required)
- UNII-3: 149-165 (5 channels, no DFS)
**Best:** Channel 100 or 149

### Europe (ETSI):
- UNII-1: 36-48
- UNII-2: 52-140 (DFS required)
- No UNII-3 (149-165 not available)
**Best:** Channel 100 or 36

### UK:
- Same as Europe
- All outdoor 5GHz requires DFS
**Best:** Channel 100 (DFS) or 36 (indoor)

### Worldwide (Safe):
- Channels 36, 40, 44, 48 (available everywhere)
**Best:** Channel 36

---

## Troubleshooting

### Problem: Frequent channel switches
```
Cause: Radar detection on DFS channel
Fix: Switch to non-DFS (36, 149) or lower power
```

### Problem: Slow 5GHz speeds despite good signal
```
Cause: Channel congestion or wrong width
Fix:
  1. Run RF scan to find cleanest channel
  2. Try DFS channels (100-144)
  3. Verify channel width is 80 MHz
```

### Problem: Devices prefer 2.4GHz over 5GHz
```
Cause: 5GHz signal too weak or band steering disabled
Fix:
  1. Increase 5GHz power to Medium
  2. Enable band steering
  3. Check minimum RSSI settings
```

---

## Best Practices

### For Maximum Performance:
```
Channel Width: 160 MHz (WiFi 6 APs)
Channel: 100 (DFS, cleanest)
Power: High (if single AP)
```

### For Maximum Stability:
```
Channel Width: 80 MHz
Channel: 36 or 149 (non-DFS)
Power: Medium
```

### For Balanced (Recommended):
```
Channel Width: 80 MHz
Channel: Auto DFS enabled
Power: Medium
Minimum RSSI: -70 dBm
```

---

## Verification Commands

### Check Current Channel:
```bash
# From UniFi Controller
Settings → System → Site → Radio Management
Look for: "Current Channel" under 5GHz

# Via SSH to AP:
mca-cli-op info | grep channel
```

### Monitor for DFS Events:
```
UniFi Controller → Settings → Notifications → Alerts
Enable: "Channel Changed" alerts
```

### Check Channel Utilization:
```
UniFi Controller → Devices → [AP] → Insights → RF Environment
Look for: Channel utilization % (aim for <50%)
```

# WiFi Channel Survey Guide

## Tools for Channel Analysis

### Option 1: WiFi Analyzer (Mobile App)
**Android:** WiFi Analyzer (by farproc)
**iOS:** WiFiMan (by Ubiquiti - free)

### Option 2: UniFi AP RF Scan
1. UniFi Controller → Devices → [Select AP] → Tools → RF Scan
2. Run scan on 2.4GHz
3. View channel utilization graph

### Option 3: Desktop Tools
- **Windows:** inSSIDer, Acrylic WiFi
- **macOS:** WiFi Explorer, iStumbler
- **Linux:** `iwlist wlan0 scan`

---

## How to Read Channel Scan Results

### What to Look For:
```
Channel 1:  ████████░░ (8/10 networks)
Channel 6:  ███░░░░░░░ (3/10 networks) ← Choose this one
Channel 11: ██████░░░░ (6/10 networks)
```

**Pick the channel with:**
1. Fewest networks
2. Weakest signal strength from neighbors
3. No overlapping channels (avoid 2,3,4,5,7,8,9,10,12,13,14)

---

## Channel Assignment for Multiple APs

If you have multiple APs in your house:

### 2-AP Setup:
```
AP1 (main floor):    Channel 1
AP2 (upstairs):      Channel 6 or 11
```

### 3-AP Setup:
```
AP1 (west wing):     Channel 1
AP2 (center):        Channel 6
AP3 (east wing):     Channel 11
```

### 4+ AP Setup:
```
Reuse channels for APs that are far apart:
AP1 (front):         Channel 1
AP2 (back):          Channel 1 (if >30ft from AP1)
AP3 (left):          Channel 6
AP4 (right):         Channel 11
```

**Rule:** Same channel is better than overlapping channels!

---

## Verification Commands

### From Linux/macOS:
```bash
# Scan for networks
sudo iwlist wlan0 scan | grep -E "(ESSID|Channel|Quality)"

# Check current connection
iwconfig wlan0 | grep -E "(Frequency|Signal)"
```

### From UniFi Controller:
1. Devices → [AP Name] → Insights → RF Environment
2. Look for channel utilization percentage
3. Aim for <50% utilization

---

## Recommended Schedule

- **Initial survey**: Before configuring channels
- **Re-survey**: Every 3-6 months (neighbors change)
- **After issues**: If WiFi performance degrades
- **After AP additions**: When adding new access points

---

## Quick Reference

### Good 2.4GHz Channels (Worldwide):
- Channel 1 (2412 MHz)
- Channel 6 (2437 MHz)
- Channel 11 (2462 MHz)

### NEVER Use These Channels:
- 2, 3, 4, 5 (overlap with 1 and 6)
- 7, 8, 9, 10 (overlap with 6 and 11)
- 12, 13, 14 (illegal in USA, limited elsewhere)

### Channel Width:
- **Always use 20 MHz** in 2.4GHz
- Exception: If you're the ONLY network in range (rare)

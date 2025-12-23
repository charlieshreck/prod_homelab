# WiFi Performance Testing Guide

## Required Tools

### Mobile Apps:
- **WiFiMan** (Ubiquiti, free) - Signal strength, speed test
- **WiFi Analyzer** (Android) - Channel analysis
- **Network Analyzer** (iOS) - Ping, traceroute, iperf

### Desktop Tools:
- **iperf3** - Throughput testing
- **ping** - Latency testing
- **speedtest-cli** - Internet speed test

---

## Test 1: Signal Strength Survey

### Walk-Through Test:
```
1. Open WiFiMan app
2. Tools → Signal Strength
3. Walk through every room in your home/office
4. Note signal strength (RSSI) in each location

Target Values:
  Excellent:  -30 to -50 dBm
  Good:       -50 to -65 dBm
  Fair:       -65 to -75 dBm
  Poor:       -75 to -85 dBm (consider adding AP)
  No Service: -85 dBm and below
```

### Heat Map (Optional):
```
Tools: Ekahau HeatMapper (free), NetSpot

Process:
1. Upload floor plan
2. Walk around while app measures signal
3. Generate heat map showing coverage
4. Identify dead zones
```

---

## Test 2: Roaming Performance

### Manual Roaming Test:
```
1. Start continuous ping:
   ping -i 0.2 10.10.0.1 > roaming-test.txt

2. Walk from AP1 coverage to AP2 coverage

3. Watch for:
   - Packet loss during transition
   - Latency spike during roaming

4. Stop ping, analyze results:
   grep "time=" roaming-test.txt | awk '{print $7}' | sort -n

Target Results:
  With 802.11r:  0-2 packets lost, <50ms spike
  Without 802.11r: 5-20 packets lost, 500-1000ms spike
```

### Automated Roaming Test:
```bash
#!/bin/bash
# Save as: test-roaming.sh

echo "Starting roaming test - walk between APs now..."
ping -c 500 -i 0.2 10.10.0.1 | tee roaming-results.txt

echo ""
echo "=== Roaming Test Results ==="
echo "Total packets sent: 500"
echo -n "Packets lost: "
grep "packets transmitted" roaming-results.txt | awk '{print $6}'
echo -n "Average latency: "
grep "avg" roaming-results.txt | awk -F'/' '{print $5}'
echo ""
```

---

## Test 3: Throughput Testing

### Internal Network Throughput (LAN):
```bash
# On server (e.g., Proxmox host or Kubernetes worker):
iperf3 -s

# On WiFi client:
# Test download (from server to client):
iperf3 -c 10.10.0.41 -t 30 -i 5

# Test upload (from client to server):
iperf3 -c 10.10.0.41 -t 30 -i 5 -R

# Bidirectional test:
iperf3 -c 10.10.0.41 -t 30 -d

Expected Results:
  2.4GHz (20 MHz):     50-150 Mbps
  5GHz (80 MHz):       300-867 Mbps
  5GHz (160 MHz):      1200-2400 Mbps
```

### Internet Speed Test:
```bash
# Install speedtest-cli:
pip3 install speedtest-cli

# Run test:
speedtest-cli --simple

# Expected (with 980 Mbps connection):
# 2.4GHz: 100-150 Mbps
# 5GHz:   800-950 Mbps (if close to AP)
```

---

## Test 4: Latency & Jitter Testing

### Basic Latency Test:
```bash
# To gateway:
ping -c 100 10.10.0.1

# To internet:
ping -c 100 1.1.1.1

Target Values:
  To Gateway:    <3ms average (5GHz), <5ms (2.4GHz)
  To Internet:   Add your ISP latency (typically +10-30ms)
  Jitter:        <2ms
```

### Advanced Latency Test (Statistics):
```bash
#!/bin/bash
# latency-test.sh

echo "Testing latency to gateway (100 pings)..."
ping -c 100 10.10.0.1 | tee latency-raw.txt

echo ""
echo "=== Latency Statistics ==="
echo -n "Min: "
grep "min/avg/max" latency-raw.txt | awk -F'/' '{print $4}' | awk '{print $3}'
echo -n "Avg: "
grep "min/avg/max" latency-raw.txt | awk -F'/' '{print $5}'
echo -n "Max: "
grep "min/avg/max" latency-raw.txt | awk -F'/' '{print $6}'
echo -n "Packet Loss: "
grep "packet loss" latency-raw.txt | awk '{print $6}'

# Calculate jitter (standard deviation):
grep "time=" latency-raw.txt | awk '{print $7}' | sed 's/time=//' | \
  awk '{sum+=$1; sumsq+=$1*$1} END {print "Jitter: " sqrt(sumsq/NR - (sum/NR)^2) " ms"}'
```

---

## Test 5: Channel Interference Testing

### Via UniFi Controller:
```
1. Devices → [Select AP] → Tools → RF Scan
2. Select band: 2.4GHz or 5GHz
3. Click "Start Scan"
4. Wait 2-5 minutes for completion

Results show:
  - Channel utilization %
  - Neighboring networks
  - Recommended channels

Target: <50% channel utilization
```

### Via WiFi Analyzer App (Android):
```
1. Open WiFi Analyzer app
2. View: Channel Graph
3. Look for gaps between networks
4. Your network should have minimal overlap

Ideal 2.4GHz:
  Your AP on channel 6
  Neighbors on channels 1 and 11 (no overlap)
```

---

## Test 6: Multi-Client Load Testing

### Simulate Heavy Usage:
```bash
# On multiple clients simultaneously:

Client 1: iperf3 -c 10.10.0.41 -t 60
Client 2: iperf3 -c 10.10.0.42 -t 60
Client 3: ping -f 10.10.0.1 (flood ping)
Client 4: speedtest-cli

# Monitor on UniFi:
Devices → [AP] → Insights → Clients
  - Watch for: Throughput per client
  - RF utilization should stay <80%
```

---

## Test 7: Band Steering Verification

### Test Band Steering:
```
1. Disconnect all WiFi clients
2. Connect dual-band device (phone/laptop)
3. Check which band it connected to:

   iOS: Settings → WiFi → (i) → Look for "Channel"
   Android: WiFi Analyzer → Your network → Frequency
   Windows: netsh wlan show interfaces | findstr "Channel"

4. Expected: Should connect to 5GHz (if in range)

If connecting to 2.4GHz when 5GHz available:
  - Enable band steering
  - Increase 5GHz power slightly
  - Decrease 2.4GHz power
```

---

## Test 8: Sticky Client Testing

### Identify Sticky Clients:
```
Scenario: Client stays on distant AP instead of roaming

Test:
1. Start ping: ping -i 0.2 10.10.0.1
2. Walk from AP1 to AP2 (far from AP1)
3. Check which AP you're connected to:

   UniFi: Clients → [Your device] → "Connected to: AP-xxx"

If still on AP1 when closer to AP2:
  - Lower minimum RSSI (more aggressive roaming)
  - Enable 802.11v (BSS Transition)
  - Reduce TX power on AP1
```

---

## Test 9: IoT Device Compatibility

### Test IoT Device Connections:
```
For each IoT device (smart bulbs, thermostats, etc.):

1. Check connection status in UniFi:
   Clients → [Device] → Properties
   - Note: Signal strength, TX/RX rates

2. Verify stable connection:
   ping -c 100 <device-ip>
   - Should have <1% packet loss

If device won't connect:
  - Disable 802.11r/k/v/w
  - Use WPA2 only (not WPA3)
  - Increase DTIM to 3 or higher
  - Set minimum data rate to 1 Mbps
```

---

## Test 10: Real-World Application Testing

### VoIP Call Quality:
```
1. Make WiFi call (WhatsApp, Discord, Zoom)
2. Walk between APs during call
3. Listen for:
   - Dropouts during roaming
   - Audio quality degradation
   - Call drops

Target: No noticeable disruption with 802.11r enabled
```

### Video Streaming:
```
1. Start 4K stream (Netflix, YouTube)
2. Monitor buffering events
3. Check bandwidth in UniFi:
   Clients → [Device] → Throughput graph

Target:
  - No buffering on 5GHz
  - Consistent 25+ Mbps throughput for 4K
```

### Gaming Latency:
```
# Console/PC game ping test
1. Join online game server
2. Note in-game latency
3. Compare wired vs WiFi

Target: WiFi adds <5ms latency vs wired
```

---

## Interpreting Results

### Good Performance Indicators:
```
✅ Signal strength: -50 to -65 dBm in most areas
✅ Roaming: <50ms disruption, <2 packets lost
✅ Throughput: >500 Mbps on 5GHz nearby AP
✅ Latency: <3ms to gateway (5GHz)
✅ Jitter: <2ms
✅ Packet loss: <0.1%
✅ Channel utilization: <50%
```

### Red Flags:
```
❌ Signal <-75 dBm in coverage area → Add AP or increase power
❌ Roaming takes >500ms → Enable 802.11r
❌ Throughput <100 Mbps on 5GHz → Check channel width, interference
❌ Latency >10ms to gateway → Check for interference, reduce TX power
❌ Packet loss >1% → Channel congestion or AP overload
❌ Channel utilization >80% → Change channel or add AP
```

---

## Ongoing Monitoring

### Daily Checks (Automated):
```bash
# Add to cron: daily-wifi-check.sh
#!/bin/bash
DATE=$(date +%Y-%m-%d)
ping -c 50 10.10.0.1 | tail -3 > /var/log/wifi-health-$DATE.log
speedtest-cli --simple >> /var/log/wifi-health-$DATE.log
```

### Weekly Review:
```
1. UniFi → Insights → Network Stats
   - Review: Client count trends
   - Look for: Unusual spikes or drops

2. UniFi → Devices → [Each AP] → Insights
   - Review: RF utilization over time
   - Look for: Increasing interference

3. Check for firmware updates
```

### Monthly Deep Dive:
```
1. Full signal strength survey
2. Re-run all performance tests
3. Compare to baseline results
4. Adjust settings as needed
```

---

## Troubleshooting Common Issues

### Slow WiFi Despite Good Signal:
```
1. Check channel utilization (should be <50%)
2. Verify channel width (80 MHz for 5GHz)
3. Test at different times (neighbor usage varies)
4. Disable airtime fairness
5. Try different channel (especially DFS on 5GHz)
```

### Frequent Disconnects:
```
1. Check minimum RSSI (may be too aggressive)
2. Disable 802.11r temporarily (compatibility test)
3. Check for DFS radar events (if on DFS channels)
4. Review UniFi logs for specific error codes
5. Update AP firmware
```

### Poor Roaming:
```
1. Enable 802.11r (if not already)
2. Lower minimum RSSI to force roaming
3. Reduce TX power to create clearer boundaries
4. Ensure APs have overlapping coverage (-65 dBm minimum)
5. Enable BSS Transition (802.11v)
```

# 🧪 LMS Alerting - Testing Guide

## Quick Local Test (No Docker Required)

### Step 1: Start Backend
```bash
cd backend
npm run dev
```

### Step 2: Run Test Script
```powershell
cd lms-observability
.\test-alerts.ps1
```

This will test:
- ✅ Backend health
- ✅ Alert webhook endpoint
- ✅ Alertmanager format (firing)
- ✅ Alertmanager format (resolved)
- ✅ Grafana webhook format

**Check your backend console** - you should see alert logs like:
```
======================================================================
📥 [ALERTMANAGER] Received 1 alert(s)
   Status: FIRING
   Receiver: critical-alerts
======================================================================
🔴 [Alertmanager] Alert FIRING: TestAlert
   Severity: critical
   Service: lms-backend
   Summary: 🧪 Test Alert - Local Testing
======================================================================
```

---

## Full Test with Email (Requires Docker)

### Step 1: Start Docker Stack
```bash
cd lms-observability
docker-compose up -d
```

### Step 2: Verify Services
```bash
docker-compose ps
```
All should show "Up (healthy)":
- lms-prometheus (port 9090)
- lms-alertmanager (port 9093)
- lms-grafana (port 3002)

### Step 3: Start Backend
```bash
cd backend
npm run dev
```

### Step 4: Test with Email
```powershell
cd lms-observability
.\test-alerts.ps1 -SendEmail
```

📧 Check **prathammodi001@gmail.com** for the test alert email!

---

## Manual Testing

### Test Webhook Directly (curl/PowerShell)

```powershell
# Fire a test alert
$body = @{
    version = "4"
    status = "firing"
    receiver = "test"
    alerts = @(@{
        status = "firing"
        labels = @{ alertname = "ManualTest"; severity = "critical"; service = "lms-backend" }
        annotations = @{ summary = "Manual test"; description = "Testing manually" }
        startsAt = (Get-Date).ToUniversalTime().ToString("o")
    })
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri "http://localhost:3000/v1/observability/alerts/webhook" -Method POST -Body $body -ContentType "application/json"
```

### Send Test Email via Alertmanager

```powershell
$alert = @(@{
    labels = @{ alertname = "EmailTest"; severity = "critical"; service = "lms-backend" }
    annotations = @{ summary = "Email Test"; description = "Testing email delivery" }
    startsAt = (Get-Date).ToUniversalTime().ToString("o")
}) | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:9093/api/v2/alerts" -Method POST -Body $alert -ContentType "application/json"
```

---

## Verify Alert Rules in Prometheus

1. Open http://localhost:9090/alerts
2. You should see all configured alerts:
   - BackendDown
   - HighCPUUsage
   - HighMemoryUsage
   - HighErrorRate
   - etc.

---

## Troubleshooting

### Backend webhook not working?
- Make sure backend has the latest code with `alert-routes.ts`
- Check route is mounted at `/v1/observability/alerts`

### Emails not sending?
```bash
docker logs lms-alertmanager
```
Check for SMTP connection errors.

### Prometheus not scraping?
- Check http://localhost:9090/targets
- Verify backend is running on port 3000

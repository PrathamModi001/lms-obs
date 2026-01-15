# LMS Alerting System

## How It Works

```
Backend Down → Prometheus detects (15s) → Alert fires (30s) → Email sent (10s)
                                         Total: ~55 seconds
```

## What Triggers Emails

| Alert | Condition | Time to Fire |
|-------|-----------|--------------|
| BackendDown | Backend unreachable | 30 sec |
| HighCPUUsage | CPU > 70% | 5 min |
| HighMemoryUsage | Memory > 700MB | 5 min |
| HighErrorRate | Errors > 5% | 5 min |
| HighResponseTime | P95 > 2s | 5 min |

## Email Configuration

- **Recipient**: `prathammodi001@gmail.com`
- **SMTP**: `smtp.c3ihub.iitk.ac.in:587`

To change recipient, edit `alertmanager/alertmanager.yml`:
```yaml
email_configs:
  - to: 'your-email@example.com'
```
Then: `docker-compose restart alertmanager`

## Files Changed

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Added Alertmanager service |
| `alertmanager/alertmanager.yml` | SMTP & routing config |
| `alertmanager/templates/default.tmpl` | Email template |
| `prometheus/alerts_comprehensive.yml` | Alert rules |
| `prometheus/prometheus.yml` | Connected to Alertmanager |

## Commands

```bash
# Start
docker-compose up -d

# Check alerts
curl http://localhost:9093/api/v2/alerts

# View logs
docker logs lms-alertmanager

# Restart after config change
docker-compose restart alertmanager
```

## Test It

1. Start backend: `npm run dev`
2. Wait 30 seconds
3. Stop backend: `Ctrl+C`
4. Wait ~1 minute
5. ✉️ Email arrives

You'll also get a "Resolved" email when backend comes back up.

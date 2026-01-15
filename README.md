# LMS Observability Stack

Monitoring stack for LMS Backend using Prometheus, Alertmanager, and Grafana.

## Quick Start

```bash
# Start the stack
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

## Services

| Service | Port | URL |
|---------|------|-----|
| Prometheus | 9090 | http://localhost:9090 |
| Alertmanager | 9093 | http://localhost:9093 |
| Grafana | 3002 | http://localhost:3002 (admin/admin) |

## Alerting

Emails are sent to `prathammodi001@gmail.com` when:

| Alert | Trigger | Wait |
|-------|---------|------|
| BackendDown | Backend unreachable | 30s |
| HighCPUUsage | CPU > 70% | 5min |
| HighMemoryUsage | Memory > 700MB | 5min |
| HighErrorRate | Errors > 5% | 5min |
| HighResponseTime | P95 > 2s | 5min |

### Change Email Recipient

Edit `alertmanager/alertmanager.yml`:
```yaml
email_configs:
  - to: 'your-email@example.com'
```

Then restart: `docker-compose restart alertmanager`

## Configuration Files

- `alertmanager/alertmanager.yml` - Email & alert routing
- `prometheus/alerts_comprehensive.yml` - Alert rules
- `prometheus/prometheus.yml` - Metrics scraping
- `grafana/dashboards/` - Dashboard JSONs

## Requirements

- Docker & Docker Compose
- LMS Backend running on port 3000
- Network access to smtp.c3ihub.iitk.ac.in:587 (for email alerts)

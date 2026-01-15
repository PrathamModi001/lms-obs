# Remote Deployment Guide

## Architecture Overview

```
┌─────────────────────────────────────────┐
│          REMOTE SERVER                   │
│  (e.g., cloud VM, VPS, dedicated server) │
│                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │ Backend │  │Frontend │  │ Worker  │ │
│  │ :3000   │  │ :3001   │  │         │ │
│  └────┬────┘  └─────────┘  └─────────┘ │
│       │                                 │
│       │ /v1/observability/prometheus-metrics
│       │                                 │
└───────┼─────────────────────────────────┘
        │
        │ HTTPS + API Key Auth
        │
┌───────┴─────────────────────────────────┐
│          LOCAL MACHINE                   │
│                                         │
│  ┌────────────┐                         │
│  │ Prometheus │────scrape───────────────┤
│  │   :9090    │                         │
│  └──────┬─────┘                         │
│         │                               │
│  ┌──────┴──────┐  ┌──────────────────┐ │
│  │   Grafana   │  │  Alertmanager    │ │
│  │    :3002    │  │     :9093        │ │
│  └─────────────┘  └──────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

## What Changes Are Needed

### 1. Prometheus Configuration

Copy `prometheus.remote.yml.example` to `prometheus.yml` and update:

```yaml
# Change from:
static_configs:
  - targets: ['host.docker.internal:3000']

# Change to:
static_configs:
  - targets: ['your-server-domain.com:3000']
  # OR with HTTPS reverse proxy (recommended):
  - targets: ['api.your-server-domain.com']
```

### 2. Alertmanager Configuration (Optional)

If your backend has a webhook endpoint for alerts, update `alertmanager.yml`:

```yaml
webhook_configs:
  # Change from:
  - url: 'http://host.docker.internal:3000/v1/observability/alerts/webhook'
  
  # Change to:
  - url: 'https://api.your-server-domain.com/v1/observability/alerts/webhook'
```

### 3. Grafana - No Changes Needed

Grafana connects to Prometheus (which is local), so no changes required.

---

## Remote Server Setup

### Firewall Rules

Allow access to the metrics endpoint port. Options:

**Option A: Direct Access (Port 3000)**
```bash
# On remote server, allow only your local IP
sudo ufw allow from YOUR_LOCAL_PUBLIC_IP to any port 3000
```

**Option B: Reverse Proxy with HTTPS (Recommended)**
```nginx
# nginx.conf
server {
    listen 443 ssl;
    server_name api.your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # Restrict metrics endpoint to specific IPs
    location /v1/observability/prometheus-metrics {
        # Allow only your monitoring IP
        allow YOUR_LOCAL_PUBLIC_IP;
        deny all;
        
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### API Key Authentication

Your metrics endpoint already requires an API key! When configuring Prometheus:

```yaml
authorization:
  type: "ApiKey"
  credentials: "YOUR_API_KEY"  # Must match backend's HEADERSAPIKEY env var
```

---

## Step-by-Step Deployment

### Step 1: Deploy Backend to Remote Server

```bash
# On remote server
git clone <your-repo>
cd LMS/backend
npm install
npm run build

# Set environment variables
export HEADERSAPIKEY=your-secure-api-key
export NODE_ENV=production
# ... other env vars

# Start backend
npm start
```

### Step 2: Verify Metrics Endpoint is Accessible

From your local machine:
```bash
# Test connectivity
curl -H "x-api-key: your-secure-api-key" https://api.your-server.com/v1/observability/prometheus-metrics
```

You should see Prometheus metrics output.

### Step 3: Update Local Prometheus Config

Edit `lms-observability/prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'lms-backend'
    metrics_path: '/v1/observability/prometheus-metrics'
    scheme: https  # Use 'http' if no SSL
    
    authorization:
      type: "ApiKey"
      credentials: "your-secure-api-key"
    
    static_configs:
      - targets: ['api.your-server-domain.com']
        labels:
          environment: 'production'
          service: 'lms-backend'
```

### Step 4: Restart Local Observability Stack

```bash
cd lms-observability
docker-compose down
docker-compose up -d
```

### Step 5: Verify Scraping Works

1. Open Prometheus at `http://localhost:9090`
2. Go to Status > Targets
3. Check that `lms-backend` target shows as "UP"

---

## Security Considerations

### Required Security Measures

1. **API Key Authentication** (Already implemented)
   - Never expose metrics endpoint without authentication
   - Use strong, unique API keys

2. **IP Whitelisting** (Recommended)
   - Only allow your monitoring server's IP to access metrics endpoint

3. **HTTPS** (Strongly Recommended for Production)
   - Encrypt traffic between Prometheus and remote backend
   - Use Let's Encrypt for free SSL certificates

### Optional: IP-Based Access Control in Backend

Add to your Express middleware:

```typescript
// middleware/ip-whitelist.ts
const ALLOWED_IPS = ['YOUR_MONITORING_SERVER_IP'];

app.use('/v1/observability/prometheus-metrics', (req, res, next) => {
  const clientIP = req.ip || req.connection.remoteAddress;
  if (!ALLOWED_IPS.includes(clientIP)) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  next();
});
```

---

## Troubleshooting

### Prometheus Shows Target as "DOWN"

1. **Check network connectivity**
   ```bash
   curl -v https://api.your-server.com/v1/observability/prometheus-metrics
   ```

2. **Verify API key is correct**
   - Check `HEADERSAPIKEY` env var on remote server
   - Check `credentials` in prometheus.yml

3. **Check firewall rules**
   - Ensure your local public IP is allowed

4. **Check Prometheus logs**
   ```bash
   docker logs lms-prometheus
   ```

### Metrics Not Appearing in Grafana

1. Verify Prometheus is scraping (Status > Targets = UP)
2. Try a query in Prometheus UI first
3. Check the datasource in Grafana points to correct Prometheus URL

### High Latency in Metrics

Remote scraping adds network latency. Consider:
- Increasing `scrape_interval` to 30s or 60s
- Using a VPN for faster connection
- Deploying Prometheus closer to your backend (same cloud region)

---

## Example Configurations

See these files for complete examples:
- `prometheus/prometheus.remote.yml.example` - Prometheus for remote deployment
- `alertmanager/alertmanager.remote.yml.example` - Alertmanager for remote deployment

# Local Observability — Connection Checklist

## Step 1 — Backend pre-flight

### 1.1 Backend running
```bash
curl http://localhost:3000/health
```
**Expected:** `{ "success": true, "data": { "logging": { "enabled": true, "logToFile": true, ... } } }`

**If fails:** run `npm run dev` in `backend/`

---

### 1.2 Metrics endpoint reachable
```bash
curl -H "Authorization: ApiKey 04VCjkU5TrL5biVxEnTzANj8TxJWJd4M" \
  http://localhost:3000/v1/observability/prometheus-metrics
```
**Expected:** plain text starting with `# HELP` lines (Prometheus format)

**If fails:** check `OTEL_EXPORT_MODE` in `backend/.env` — must be `prometheus` (default, only breaks if explicitly overridden)

---

### 1.3 Log files being written
```bash
ls backend/observability-data/logs/
```
**Expected:** folder with today's date (e.g. `2026-05-08/`) containing `combined.json`, `errors.json`, etc.

**If empty/missing:**
- `LOG_TO_FILE` defaults ON — check `LOG_TO_FILE=false` isn't set in backend `.env`
- Health check route is excluded from logging — make a real request to any `/v1/` route first

---

## Step 2 — Start obs stack

```bash
cd lms-observability/

# confirm TARGET_ENV=local in .env
cat .env | grep TARGET_ENV

docker-compose up -d
```

Wait ~30s then verify all services are healthy:
```bash
docker-compose ps
```
All should show `healthy`. If any stuck on `starting` after 60s:
```bash
docker-compose logs prometheus
docker-compose logs loki
```

---

## Step 3 — Prometheus target UP

Open: **http://localhost:9090/targets**

Look for job `lms-backend` → Status: **UP**

**If DOWN — check the error message:**

| Error | Fix |
|---|---|
| `connection refused` | Backend not running on port 3000 |
| `401 Unauthorized` | Wrong ApiKey — check `HEADERSAPIKEY` in `.env` |
| `dial tcp: no such host` | `host.docker.internal` not resolving — set `LOCAL_BACKEND_HOST=<your LAN IP>` in `.env`, then `docker-compose up -d prometheus` |
| `context deadline exceeded` | Firewall blocking — allow port 3000 |

**Verify envsubst ran correctly (vars should be resolved, not raw `${...}`):**
```bash
docker exec lms-prometheus cat /tmp/prom.yml
```

---

### 3.1 Prometheus has metric data

Go to **http://localhost:9090/graph** and run:
```
up{job="lms-backend"}
```
**Expected:** returns `1`

Then verify real metrics (make a few backend requests first):
```
http_server_request_duration_count
```
**Expected:** returns values

---

## Step 4 — Grafana dashboards

Open: **http://localhost:3002**
Login: `c3i-123-890` / `c3i-123-890`

### 4.1 Overview dashboard loads
Home should auto-open `overview.json`. Stat panels should show numbers. "Backend Status" should be **green / UP**.

### 4.2 No datasource errors
No red "Datasource not found" banners anywhere.

**If you see them:** Connections → Data sources → verify `prometheus` UID is `prometheus` and `loki` UID is `loki`

### 4.3 Complete Analytics dashboard
Open "LMS Backend - Complete Website Analytics".
- HTTP panels: should have data after a few requests
- MongoDB/Redis panels: show 0 until real DB/cache operations happen — that's normal

---

## Step 5 — Loki logs

### 5.1 Loki healthy
```bash
curl http://localhost:3100/ready
```
**Expected:** `ready`

---

### 5.2 Logs reaching Loki

Grafana → **Explore** → datasource: **Loki**

Query:
```
{job="lms-backend"}
```
**Expected:** log lines appearing (hit a real `/v1/` route first to generate logs)

**If no logs:**
```bash
docker-compose logs promtail --tail=50
```
Look for errors about `/var/log/backend`.

Then verify the volume mount:
```bash
docker exec lms-promtail ls /var/log/backend/
```
**Expected:** today's date folder. If `No such file or directory` — backend hasn't written any logs yet (check step 1.3).

---

### 5.3 Level labels work
```
{job="lms-backend", level="E"}
```
Should return error-level logs only.

**If all logs show `level=""`:** json parse stage isn't matching. Make a bad request to generate a log with the `l` field, then check again:
```bash
curl http://localhost:3000/v1/nonexistent
```

---

## Step 6 — Alertmanager

### 6.1 Alertmanager healthy
Open: **http://localhost:9093**

Should show Alertmanager UI, Status → **Ready**

### 6.2 Config resolved correctly
```bash
docker exec lms-alertmanager cat /tmp/am.yml
```
Webhook URLs should show `http://host.docker.internal:3000/v1/...` — not raw `${LOCAL_BACKEND_HOST}`.

---

## Step 7 — Incidents dashboard (end-to-end)

Open the **Incident Response** dashboard in Grafana.

- "Backend Status" → green `UP`
- "Fatal Events (15m)" → `0` (good)
- Fatal/Error log panels at bottom → logs visible if any errors occurred

---

## Quick smoke test (generate real data)

Run this to populate all panels:
```bash
# generates HTTP metrics + request logs
curl http://localhost:3000/v1/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"wrong"}'

# generates a 404 error log
curl http://localhost:3000/v1/nonexistent

# verify Prometheus received it
curl "http://localhost:9090/api/v1/query?query=http_server_request_duration_count"
```

Wait 15s, then refresh Grafana — HTTP panels, error panels, and Loki logs should all show data.

---

## Known local-only gaps (not bugs)

| Panel | Behaviour | Reason |
|---|---|---|
| Unique IPs | Always shows 0 | `client_ip` label not attached to HTTP metric |
| Tempo traces | No trace data | Set `OTEL_TEMPO_ENDPOINT=http://localhost:3200/v1/traces` in `backend/.env` |
| Email alerts | Won't fire | No SMTP in `alertmanager.local.yml` — intentional |

---

## Switching environments

Edit `lms-observability/.env`, then restart only prometheus + alertmanager:

```bash
# .env
TARGET_ENV=local       # host.docker.internal:3000
TARGET_ENV=staging     # lmsgov.live
TARGET_ENV=production  # lms.c3ihub.iitk.ac.in

# apply
docker-compose up -d prometheus alertmanager
```
No data loss — all volumes are preserved on restart.

# 📊 LMS Observability Stack

> Real-time monitoring for **https://lms.c3ihub.iitk.ac.in**

---

## 🔄 How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PRODUCTION SERVER                                    │
│                    (lms.c3ihub.iitk.ac.in)                                   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                      LMS Backend (Node.js)                            │   │
│  │                                                                       │   │
│  │   ┌─────────────────┐    ┌─────────────────┐    ┌────────────────┐   │   │
│  │   │  OpenTelemetry  │───▶│   Prometheus    │───▶│    Metrics     │   │   │
│  │   │      SDK        │    │    Exporter     │    │   :9464        │   │   │
│  │   └─────────────────┘    └─────────────────┘    └───────┬────────┘   │   │
│  │           │                                              │           │   │
│  │           ▼                                              │           │   │
│  │   Auto-instruments:                                      │           │   │
│  │   • HTTP requests                                        │           │   │
│  │   • Response times                                       │           │   │
│  │   • Error rates                                          │           │   │
│  │   • MongoDB queries                                      │           │   │
│  └──────────────────────────────────────────────────────────┼───────────┘   │
│                                                              │               │
│                    Exposed via: /api/v1/observability/prometheus-metrics    │
│                                                              │               │
└──────────────────────────────────────────────────────────────┼───────────────┘
                                                               │
                              HTTPS + API Key Auth             │
                                                               │
┌──────────────────────────────────────────────────────────────┼───────────────┐
│                         LOCAL MACHINE                        │               │
│                                                              ▼               │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    PROMETHEUS (:9090)                                │   │
│   │                                                                      │   │
│   │    • Scrapes metrics every 15s                                       │   │
│   │    • Stores time-series data (30 days)                              │   │
│   │    • Evaluates alert rules                                          │   │
│   └───────────────────────┬─────────────────────┬───────────────────────┘   │
│                           │                     │                            │
│              ┌────────────┴──────┐    ┌────────┴────────┐                   │
│              ▼                   ▼    ▼                 ▼                   │
│   ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐       │
│   │  GRAFANA (:3002) │   │ ALERTMANAGER     │   │                  │       │
│   │                  │   │    (:9093)       │   │   📧 EMAIL       │       │
│   │  📈 Dashboards   │   │                  │──▶│                  │       │
│   │  📊 Visualize    │   │  🔔 Route alerts │   │  Alert sent to   │       │
│   │  🔍 Query        │   │  📧 Send emails  │   │  admin inbox     │       │
│   └──────────────────┘   └──────────────────┘   └──────────────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🧩 Stack Roles

| Component | Role | One-liner |
|-----------|------|-----------|
| **OpenTelemetry** | 📡 Collector | Auto-instruments code, captures metrics |
| **Prometheus** | 💾 Storage | Scrapes, stores, queries time-series data |
| **Grafana** | 📊 Visualizer | Beautiful dashboards & charts |
| **Alertmanager** | 🔔 Notifier | Routes alerts → Email/Webhook |

---

## ⚡ Quick Start

```bash
cd lms-observability
docker-compose up -d --build
```

---

## 🌐 Access

| Service | URL | Auth |
|---------|-----|------|
| **Prometheus** | http://localhost:9090 | - |
| **Grafana** | http://localhost:3002 | `admin` / `admin` |
| **Alertmanager** | http://localhost:9093 | - |

---

## 🔔 Active Alerts

| Alert | Trigger | Severity |
|-------|---------|----------|
| `BackendDown` | Service unreachable 30s | 🔴 Critical |
| `HighErrorRate` | 5xx errors > 5% | 🔴 Critical |
| `HighCPUUsage` | CPU > 70% for 5min | 🟡 Warning |
| `HighMemoryUsage` | Memory > 700MB | 🟡 Warning |
| `HighResponseTime` | P95 > 2s | 🟡 Warning |

**Alerts → Email:** `prathammodi001@gmail.com`

---

## 📁 Key Files

```
lms-observability/
├── docker-compose.yml          # Stack definition
├── prometheus/
│   ├── prometheus.yml          # Scrape config (target: production)
│   └── alerts_comprehensive.yml # Alert rules
├── alertmanager/
│   └── alertmanager.yml        # Email routing
└── grafana/
    └── dashboards/             # Pre-built dashboards
```

---

## 🛠️ Common Commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Restart after config change
docker-compose restart prometheus

# View logs
docker-compose logs -f prometheus

# Check targets
# Open: http://localhost:9090/targets
```

---

## ✅ Verify It's Working

1. **Prometheus** → Status → Targets → `lms-backend` should be **UP** 🟢
2. **Grafana** → Dashboards → See live metrics from production
3. **Alertmanager** → Check alert status

---

## 🔐 Security

- ✅ API Key authentication for metrics endpoint
- ✅ HTTPS connection to production
- ✅ Monitoring is read-only (doesn't affect production)


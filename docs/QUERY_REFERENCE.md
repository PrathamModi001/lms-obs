# LGTM Stack Query Reference

Quick reference for querying your LMS backend observability stack on localhost.

---

## 🚨 Disaster Response Queries

### When Things Go Wrong

#### 1. Find Recent Errors (Last 5 Minutes)

**Loki - All Error Logs:**
```logql
{cluster="lms-observability"} |= "error" | json | line_format "{{.time}} [{{.lvl}}] {{.event}} - {{.msg}}"
```

**Loki - Backend Errors Only:**
```logql
{service_name="lms-backend"} | json | lvl="E"
```

**Prometheus - Error Rate Spike:**
```promql
rate(http_server_request_duration_count{http_status_code=~"5.."}[5m])
```

---

#### 2. Trace a Failed Request

**Find failing traces in Tempo:**
```
{status=error}
```

**Find slow requests (>1s):**
```
{duration>1s}
```

**Get trace by ID (from logs):**
```
# In Tempo search bar, paste the traceId from logs
```

---

#### 3. Which Service is Crashing?

**Loki - Container Restart Events:**
```logql
{cluster="lms-observability"} |~ "Starting|Restarting|Stopped"
```

**Prometheus - Container Restarts:**
```promql
increase(container_restarts_total{service="lms-backend"}[1h])
```

---

#### 4. Memory/CPU Crisis

**Prometheus - High Memory Usage:**
```promql
process_resident_memory_bytes / 1024 / 1024 > 500
```

**Prometheus - High CPU:**
```promql
rate(process_cpu_seconds_total[5m]) * 100 > 80
```

**Prometheus - Event Loop Lag:**
```promql
nodejs_eventloop_lag_seconds > 0.1
```

---

#### 5. Database Connection Issues

**Loki - MongoDB Errors:**
```logql
{service_name="lms-backend"} | json | msg =~ "(?i)mongo|database|connection"
```

**Prometheus - Connection Pool Exhausted:**
```promql
mongodb_connection_pool_size - mongodb_connection_pool_available_connections < 2
```

---

#### 6. Full Disaster Timeline

**Loki - All Events Around Specific Time:**
```logql
{cluster="lms-observability"} | json | line_format "{{.time}} [{{.container_name}}] {{.lvl}} - {{.event}}"
```

**Tempo - Traces During Incident:**
```
{.service.name="lms-backend"} && .start > 2026-01-28T12:00:00Z && .start < 2026-01-28T12:30:00Z
```

---

## 💚 Health Check Queries

### Daily Operations Monitoring

#### 1. Request Success Rate

**Prometheus - Overall Success Rate:**
```promql
sum(rate(http_server_request_duration_count{http_status_code!~"5.."}[5m])) 
/ 
sum(rate(http_server_request_duration_count[5m])) * 100
```

**Prometheus - Requests Per Minute:**
```promql
sum(rate(http_server_request_duration_count[1m])) * 60
```

---

#### 2. Response Time Health

**Prometheus - P95 Response Time:**
```promql
histogram_quantile(0.95, rate(http_server_request_duration_bucket[5m]))
```

**Prometheus - Average Response Time:**
```promql
rate(http_server_request_duration_sum[5m]) / rate(http_server_request_duration_count[5m])
```

---

#### 3. System Resources

**Prometheus - Memory Usage:**
```promql
process_resident_memory_bytes / 1024 / 1024
```

**Prometheus - CPU Usage:**
```promql
rate(process_cpu_seconds_total[5m]) * 100
```

**Prometheus - Heap Usage:**
```promql
nodejs_heap_size_used_bytes / nodejs_heap_size_total_bytes * 100
```

---

#### 4. Traffic Patterns

**Loki - Request Count by Endpoint:**
```logql
sum by (route) (count_over_time({service_name="lms-backend"} | json | __error__="" [5m]))
```

**Prometheus - Top Endpoints:**
```promql
topk(10, sum by (http_route) (rate(http_server_request_duration_count[5m])))
```

---

#### 5. Active Connections

**Prometheus - Active Users:**
```promql
active_users
```

**Prometheus - Redis Connections:**
```promql
redis_connected_clients
```

---

## 🔍 Important Operational Queries

### Troubleshooting & Analysis

#### 1. Trace-to-Log Correlation

**Step 1 - Find trace in Tempo:**
```
{.http.route="/api/v1/auth/login"}
```

**Step 2 - Click trace → Get trace ID**

**Step 3 - Search logs with trace ID:**
```logql
{service_name="lms-backend"} | json | tid="<paste_trace_id_here>"
```

---

#### 2. User Activity Analysis

**Loki - Specific User's Actions:**
```logql
{service_name="lms-backend"} | json | uid="<user_id>"
```

**Tempo - User's Request Traces:**
```
{.user.id="<user_id>"}
```

---

#### 3. Authentication Issues

**Loki - Auth Failures:**
```logql
{service_name="lms-backend"} | json | event =~ "auth.*" | lvl="E"
```

**Loki - Login Activity:**
```logql
{service_name="lms-backend"} | json | event="auth.login.success"
```

---

#### 4. API Performance by Route

**Prometheus - Slowest Endpoints:**
```promql
topk(10, 
  rate(http_server_request_duration_sum[5m]) 
  / 
  rate(http_server_request_duration_count[5m])
) by (http_route)
```

**Tempo - Slow Traces by Route:**
```
{.http.route="/api/v1/courses"} && duration > 500ms
```

---

#### 5. Cache Hit/Miss Analysis

**Prometheus - Cache Hit Rate:**
```promql
sum(rate(cache_hits_total[5m])) / (sum(rate(cache_hits_total[5m])) + sum(rate(cache_misses_total[5m]))) * 100
```

**Loki - Cache Events:**
```logql
{service_name="lms-backend"} | json | event =~ "cache.*"
```

---

#### 6. Database Query Performance

**Loki - Slow MongoDB Queries:**
```logql
{service_name="lms-backend"} | json | msg =~ "(?i)mongodb.*slow"
```

**Prometheus - MongoDB Operations Rate:**
```promql
rate(mongodb_operations_total[5m])
```

---

#### 7. Worker Process Monitoring (Cluster Mode)

**Prometheus - Metrics Per Worker:**
```promql
sum by (worker_id) (rate(http_server_request_duration_count[5m]))
```

**Loki - Logs from Specific Worker:**
```logql
{service_name="lms-backend"} | json | worker_id="<worker_id>"
```

---

#### 8. Email/Notification Health

**Prometheus - Email Success Rate:**
```promql
sum(rate(emails_sent_total[5m])) / (sum(rate(emails_sent_total[5m])) + sum(rate(emails_failed_total[5m]))) * 100
```

**Loki - Email Failures:**
```logql
{service_name="lms-backend"} | json | event =~ "email.*fail"
```

---

#### 9. S3/Storage Operations

**Prometheus - Upload Success Rate:**
```promql
sum(rate(s3_uploads_total{success="true"}[5m])) / sum(rate(s3_uploads_total[5m])) * 100
```

**Prometheus - Average Upload Size:**
```promql
avg(rate(s3_upload_size_bytes[5m]))
```

---

#### 10. Queue/Job Processing

**Prometheus - Job Success Rate:**
```promql
sum(rate(queue_jobs_completed_total[5m])) / (sum(rate(queue_jobs_completed_total[5m])) + sum(rate(queue_jobs_failed_total[5m]))) * 100
```

**Loki - Failed Jobs:**
```logql
{service_name="lms-backend"} | json | event =~ "queue.*fail"
```

---

## 📊 Grafana Combined Queries

### Multi-Source Correlation

#### Service Overview Dashboard
```promql
# Panel 1: Request Rate
sum(rate(http_server_request_duration_count[5m]))

# Panel 2: Error Rate
sum(rate(http_server_request_duration_count{http_status_code=~"5.."}[5m]))

# Panel 3: P95 Latency
histogram_quantile(0.95, rate(http_server_request_duration_bucket[5m]))
```

```logql
# Panel 4: Recent Errors
{service_name="lms-backend"} | json | lvl="E"
```

---

## 🛠️ API Access Examples

### Using PowerShell

#### Query Loki
```powershell
Invoke-RestMethod -Uri 'http://localhost:3100/loki/api/v1/query?query=%7Bservice_name%3D%22lms-backend%22%7D&limit=10' | ConvertTo-Json -Depth 5
```

#### Query Tempo
```powershell
Invoke-RestMethod -Uri "http://localhost:3200/api/search?limit=10" | ConvertTo-Json
```

#### Query Prometheus
```powershell
Invoke-RestMethod -Uri "http://localhost:9090/api/v1/query?query=up" | ConvertTo-Json
```

---

## 🎯 Quick Response Checklist

### When Alerts Fire:

1. **Check Error Rate** → Prometheus dashboard
2. **Find Recent Errors** → Loki error query
3. **Identify Failing Traces** → Tempo status=error
4. **Correlate Logs** → Use trace ID from Tempo in Loki
5. **Check Resources** → Prometheus CPU/Memory
6. **Review Timeline** → Loki time-range query

---

## 📝 Query Best Practices

1. **Always specify time range** - Default is last 1 hour
2. **Use labels for filtering** - Faster than regex
3. **Start broad, then narrow** - Find the pattern, then drill down
4. **Correlate across sources** - Logs → Traces → Metrics
5. **Save useful queries** - Add to Grafana as saved searches

---

## 🔗 Access URLs

- **Grafana**: http://localhost:3002 (Explore tab for ad-hoc queries)
- **Prometheus**: http://localhost:9090/graph
- **Loki**: http://localhost:3100 (via Grafana)
- **Tempo**: http://localhost:3200 (via Grafana)

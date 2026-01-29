# Getting Backend Logs into Loki

## ✅ Setup Complete!

Your backend logs will now flow to Loki with full trace ID correlation.

---

## What Was Configured

### 1. **Promtail Configuration**
Added a file scraping job (`backend-files`) that:
- Reads logs from `e:\LMS\backend\observability-data\logs\logs-*.json`
- Parses JSON fields including `tid` (trace ID), `sid` (span ID)
- Adds labels: `cluster=lms-observability`, `service_name=lms-backend`, `environment=local`

### 2. **Docker Compose Changes**
- Mounted backend logs directory into Promtail container at `/var/log/backend`
- Promtail can now read your local backend log files

---

## How to Generate Logs & See Correlation

### Step 1: Browse Your LMS Website

Go to **http://localhost:3001** and do any of these:

- **Login** → `http://localhost:3001/login`
- **Dashboard** → `http://localhost:3001/dashboard`
- **Browse Courses** → `http://localhost:3001/courses`
- **View Profile** → `http://localhost:3001/profile`
- **Any API call** - Every request generates logs + traces

### Step 2: Wait 10-15 Seconds

Give Promtail time to:
1. Read the new log file
2. Parse the JSON format
3. Send logs to Loki

### Step 3: Query in Grafana

#### **Open Grafana**: http://localhost:3002
-  Login: `admin` / `admin`

---

## Loki Queries to Find Your Logs

### See ALL Backend Logs:
```logql
{service_name="lms-backend"}
```

### Filter by Event:
```logql
{service_name="lms-backend", event="auth.login.success"}
```

### Find Logs with Trace IDs:
```logql
{service_name="lms-backend"} | json | trace_id != ""
```

### Get Logs for Specific Trace:
```logql
{service_name="lms-backend"} | json | trace_id="<paste_trace_id_from_tempo>"
```

---

## The Magic: Logs ↔ Traces Correlation

### From Loki to Tempo:

1. **Run query** in Loki: `{service_name="lms-backend"}`
2. **Find a log line** with a trace ID
3. **Click on the `trace_id` field** → Opens trace in Tempo! ✨

### From Tempo to Loki:

1. **Open trace** in Tempo
2. **Click "Logs for this span"** button
3. **See correlated logs** from Loki! ✨

---

## Example Workflow

### 1. Login to your LMS
```
http://localhost:3001/login
```

### 2. Open Grafana Explore → Loki
```logql
{service_name="lms-backend", event="auth.login.success"}
```

### 3. Click on a log entry → Expand it

You'll see fields like:
```json
{
  "l": "I",
  "e": "auth.login.success",
  "tid": "30e1dde035b82ebcb96041781dbd0922",
  "sid": "9bce313d5b0bff0d",
  "u": "user_id_here"
}
```

### 4. Click the `tid` value

→ **Grafana jumps to Tempo and shows the full trace!**

Now you can see:
- All spans in the request
- Duration breakdown
- Related logs
- Service dependencies

---

## Troubleshooting

### No Logs Appearing?

1. **Check backend is running**: `Get-Process -Name node`
2. **Check log files exist**:
   ```powershell
   Get-ChildItem e:\LMS\backend\observability-data\logs
   ```
3. **Browse your website** to generate requests
4. **Wait 10-15 seconds** for Promtail to scrape
5. **Check Promtail logs**:
   ```powershell
   docker logs lms-promtail --tail 30
   ```

### Logs Not Correlated?

- Make sure you're clicking on logs that have a `trace_id` field
- Not all logs have traces (only HTTP requests do)
- The `tid` field must match a trace ID in Tempo

---

## What Next?

Now that you have full correlation:

1. **Generate activity** on your website
2. **Monitor in Grafana** - Explore → Loki/Tempo
3. **Click trace IDs** to jump between logs and traces
4. **Use queries** from `QUERY_REFERENCE.md` for deeper analysis

**You now have full observability!** 🎉

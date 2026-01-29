# Generate LMS Activity for Observability Testing

## Quick Commands to Generate Traffic

Run these PowerShell commands to hit your local backend and generate logs/traces:

### 1. Generate Multiple Requests
```powershell
# Hit the /api/v1/auth/refresh endpoint 20 times
# This is a GET endpoint that generates traces/metrics even though it returns 401 without a valid token
1..20 | ForEach-Object {
    try {
        Invoke-WebRequest -Uri "http://localhost:3000/api/v1/auth/refresh" -UseBasicParsing -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Request $_ completed"
    } catch {
        # Expected to fail with 401, but still generates traces
        Write-Host "Request $_ - Generated trace (401 expected)"
    }
    Start-Sleep -Milliseconds 300
}
```

### 2. Check Traces in Tempo
```powershell
Invoke-RestMethod -Uri "http://localhost:3200/api/search?limit=10" | ConvertTo-Json -Depth 3
```

### 3. Check Prometheus Metrics
```powershell
Invoke-RestMethod -Uri "http://localhost:9464/metrics" | Select-String -Pattern "http_server"
```

## On Your LMS Website

### High-Value Actions (Generate Rich Data):

1. **Login Flow**
   - Go to: `http://localhost:3001/login`
   - Login with credentials
   - Generates: Auth traces, Redis cache checks, DB queries

2. **Course Browsing**
   - Go to: `http://localhost:3001/courses`
   - Click on different courses
   - Generates: Read operations, cache hits/misses

3. **User Dashboard**
   - Go to: `http://localhost:3001/dashboard`
   - Generates: Aggregated queries, multiple service calls

4. **Search**
   - Use search functionality
   - Generates: Complex DB queries, trace spans

5. **Enrollment**
   - Enroll in a course
   - Generates: Write operations, notifications, queue jobs

6. **Profile Updates**
   - Update user profile
   - Upload images (generates S3 traces)

### What Gets Generated:

Each action creates:
- ✅ **Trace** in Tempo (with trace ID)
- ✅ **Metrics** in Prometheus (request count, duration)
- ✅ **File Logs** in `e:\LMS\backend\logs` (with trace ID)

### Where to See the Data:

- **Tempo (Traces)**: http://localhost:3002 → Explore → Tempo
- **Prometheus (Metrics)**: http://localhost:3002 → Explore → Prometheus
- **Local Logs**: `e:\LMS\backend\logs\*.log` files

---

## Optional: Get Backend Logs into Loki

Since your backend is local (not Docker), you have 2 options:

### Option 1: Use File-based Logs (Current)
Your logs are in: `e:\LMS\backend\logs\`
- View with: `Get-Content e:\LMS\backend\logs\combined.log -Tail 50`

### Option 2: Run Backend in Docker (Future)
If you want logs in Loki too, run backend in Docker so Promtail can collect them.

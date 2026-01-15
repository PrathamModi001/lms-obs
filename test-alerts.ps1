# =============================================================================
# LMS Alerting Test Script (PowerShell)
# Run: .\test-alerts.ps1
# =============================================================================

param(
    [switch]$SendEmail,
    [string]$BackendUrl = "http://localhost:3000",
    [string]$AlertmanagerUrl = "http://localhost:9093"
)

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " LMS Alerting System - Local Test" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# Test 1: Check Backend is Running
# =============================================================================
Write-Host "TEST 1: Checking Backend Health..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$BackendUrl/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  OK - Backend is running!" -ForegroundColor Green
} catch {
    Write-Host "  FAIL - Backend not reachable at $BackendUrl" -ForegroundColor Red
    Write-Host "  Please start your backend first: cd backend && npm run dev" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""

# =============================================================================
# Test 2: Check Alert Webhook Endpoint Exists
# =============================================================================
Write-Host "TEST 2: Checking Alert Webhook Endpoint..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$BackendUrl/v1/observability/alerts/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  OK - Alert webhook endpoint is available!" -ForegroundColor Green
    Write-Host "  Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    Write-Host "  FAIL - Alert webhook endpoint not found!" -ForegroundColor Red
    Write-Host "  Make sure you have the latest backend code with alert-routes.ts" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""

# =============================================================================
# Test 3: Send Test Alert (Simulating Alertmanager)
# =============================================================================
Write-Host "TEST 3: Sending Test Alert to Backend Webhook..." -ForegroundColor Yellow

$testAlert = @{
    version = "4"
    groupKey = "test-group-$(Get-Date -Format 'HHmmss')"
    truncatedAlerts = 0
    status = "firing"
    receiver = "critical-alerts"
    groupLabels = @{ alertname = "TestAlert" }
    commonLabels = @{ alertname = "TestAlert"; severity = "critical"; service = "lms-backend" }
    commonAnnotations = @{ summary = "Test alert"; description = "This is a local test" }
    externalURL = "http://localhost:9093"
    alerts = @(
        @{
            status = "firing"
            labels = @{
                alertname = "TestAlert"
                severity = "critical"
                service = "lms-backend"
                category = "test"
            }
            annotations = @{
                summary = "Test Alert - Local Testing"
                description = "This is a test alert sent locally to verify the webhook is working correctly."
            }
            startsAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            generatorURL = "http://localhost:9090"
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$BackendUrl/v1/observability/alerts/webhook" `
        -Method POST `
        -Body $testAlert `
        -ContentType "application/json" `
        -TimeoutSec 10 `
        -ErrorAction Stop
    
    Write-Host "  OK - Alert webhook received successfully!" -ForegroundColor Green
    Write-Host "  Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Check your backend console for the alert log!" -ForegroundColor Cyan
} catch {
    Write-Host "  FAIL - Failed to send test alert!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# =============================================================================
# Test 4: Send Resolved Alert
# =============================================================================
Write-Host "TEST 4: Sending Resolved Alert..." -ForegroundColor Yellow

$resolvedAlert = @{
    version = "4"
    groupKey = "test-group-$(Get-Date -Format 'HHmmss')"
    truncatedAlerts = 0
    status = "resolved"
    receiver = "critical-alerts"
    groupLabels = @{ alertname = "TestAlert" }
    commonLabels = @{ alertname = "TestAlert"; severity = "critical"; service = "lms-backend" }
    commonAnnotations = @{ summary = "Test alert resolved"; description = "The test alert has been resolved" }
    externalURL = "http://localhost:9093"
    alerts = @(
        @{
            status = "resolved"
            labels = @{
                alertname = "TestAlert"
                severity = "critical"
                service = "lms-backend"
                category = "test"
            }
            annotations = @{
                summary = "Test Alert Resolved"
                description = "The test alert has been resolved successfully."
            }
            startsAt = (Get-Date).AddMinutes(-5).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            endsAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            generatorURL = "http://localhost:9090"
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$BackendUrl/v1/observability/alerts/webhook" `
        -Method POST `
        -Body $resolvedAlert `
        -ContentType "application/json" `
        -TimeoutSec 10 `
        -ErrorAction Stop
    
    Write-Host "  OK - Resolved alert sent successfully!" -ForegroundColor Green
} catch {
    Write-Host "  FAIL - Failed to send resolved alert!" -ForegroundColor Red
}

Write-Host ""

# =============================================================================
# Test 5: Test Grafana Webhook Format
# =============================================================================
Write-Host "TEST 5: Testing Grafana Webhook Format..." -ForegroundColor Yellow

$grafanaAlert = @{
    receiver = "grafana-default"
    status = "firing"
    alerts = @(
        @{
            status = "firing"
            labels = @{
                alertname = "GrafanaTestAlert"
                severity = "warning"
                service = "lms-backend"
            }
            annotations = @{
                summary = "Grafana Test Alert"
                description = "This simulates a Grafana unified alerting webhook"
            }
            startsAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
    )
    groupLabels = @{ alertname = "GrafanaTestAlert" }
    commonLabels = @{ alertname = "GrafanaTestAlert" }
    commonAnnotations = @{}
    externalURL = "http://localhost:3002"
    version = "1"
    groupKey = "grafana-test"
    truncatedAlerts = 0
    title = "FIRING - GrafanaTestAlert"
    state = "alerting"
    message = "Test message from Grafana"
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "$BackendUrl/v1/observability/alerts/grafana-webhook" `
        -Method POST `
        -Body $grafanaAlert `
        -ContentType "application/json" `
        -TimeoutSec 10 `
        -ErrorAction Stop
    
    Write-Host "  OK - Grafana webhook format works!" -ForegroundColor Green
} catch {
    Write-Host "  FAIL - Grafana webhook failed!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# =============================================================================
# Optional: Test Alertmanager Email (requires Docker)
# =============================================================================
if ($SendEmail) {
    Write-Host "TEST 6: Sending Test Email via Alertmanager..." -ForegroundColor Yellow
    Write-Host "  Email will be sent to: prathammodi001@gmail.com" -ForegroundColor Cyan
    
    try {
        $null = Invoke-RestMethod -Uri "$AlertmanagerUrl/-/healthy" -TimeoutSec 5 -ErrorAction Stop
        
        $emailAlert = @(
            @{
                labels = @{
                    alertname = "TestEmailAlert"
                    severity = "critical"
                    service = "lms-backend"
                    category = "test"
                }
                annotations = @{
                    summary = "Test Email Alert - LMS Alerting"
                    description = "This is a test email alert sent at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'). If you receive this, your email alerting is working!"
                }
                startsAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        ) | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri "$AlertmanagerUrl/api/v2/alerts" `
            -Method POST `
            -Body $emailAlert `
            -ContentType "application/json" `
            -TimeoutSec 10 `
            -ErrorAction Stop
        
        Write-Host "  OK - Email alert sent to Alertmanager!" -ForegroundColor Green
        Write-Host "  Check prathammodi001@gmail.com in 30-60 seconds" -ForegroundColor Cyan
    } catch {
        Write-Host "  FAIL - Alertmanager not reachable at $AlertmanagerUrl" -ForegroundColor Red
        Write-Host "  Start Docker stack: cd lms-observability && docker-compose up -d" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# =============================================================================
# Summary
# =============================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Local Test Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "What was tested:" -ForegroundColor Yellow
Write-Host "  - Backend health check" -ForegroundColor White
Write-Host "  - Alert webhook endpoint availability" -ForegroundColor White
Write-Host "  - Alertmanager webhook format (firing)" -ForegroundColor White
Write-Host "  - Alertmanager webhook format (resolved)" -ForegroundColor White
Write-Host "  - Grafana webhook format" -ForegroundColor White
if ($SendEmail) {
    Write-Host "  - Email alert via Alertmanager" -ForegroundColor White
}
Write-Host ""
Write-Host "To test email alerts, run:" -ForegroundColor Yellow
Write-Host "  1. Start Docker: cd lms-observability && docker-compose up -d" -ForegroundColor Gray
Write-Host "  2. Run: .\test-alerts.ps1 -SendEmail" -ForegroundColor Gray
Write-Host ""

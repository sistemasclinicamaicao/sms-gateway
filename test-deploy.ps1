# Smoke test for SMS Gateway on EasyPanel
$BaseUrl = 'https://chat-sms-gateway.rhfh8t.easypanel.host'
$paths = @(
    '/health',
    '/api/3rdparty/v1/health',
    '/api/3rdparty/v1/health/live',
    '/api/3rdparty/v1/health/ready'
)

Write-Host "=== SMS Gateway deploy test ===" -ForegroundColor Cyan
Write-Host "Base: $BaseUrl`n"

$passed = 0
$failed = 0

foreach ($path in $paths) {
    $url = "$BaseUrl$path"
    try {
        $r = Invoke-WebRequest -Uri $url -TimeoutSec 25 -UseBasicParsing
        if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300) {
            Write-Host "[PASS] $($r.StatusCode) $path" -ForegroundColor Green
            if ($r.Content.Length -le 300) { Write-Host "       $($r.Content)" }
            $passed++
        } else {
            Write-Host "[FAIL] $($r.StatusCode) $path" -ForegroundColor Red
            $failed++
        }
    } catch {
        $code = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        Write-Host "[FAIL] $code $path - $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passed / $($paths.Count)"

if ($failed -gt 0) {
    Write-Host "`n502/connection errors usually mean:" -ForegroundColor Yellow
    Write-Host "  - backend container is down (check MariaDB Error 1045 in logs)"
    Write-Host "  - domain not mapped to backend:8080 in EasyPanel"
    Write-Host "  - delete the MariaDB volume and redeploy after setting .env"
    exit 1
}

exit 0

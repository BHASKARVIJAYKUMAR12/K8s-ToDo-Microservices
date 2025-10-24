# Stop all local development services

Write-Host "🛑 Stopping all local development services..." -ForegroundColor Yellow

# Stop all node processes running the services
Get-Job | Remove-Job -Force

# Also kill any node processes on the service ports (if script was terminated)
$ports = @(3000, 3001, 3002, 3003, 8080)

foreach ($port in $ports) {
    $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | 
                Select-Object -ExpandProperty OwningProcess -Unique
    
    if ($process) {
        Write-Host "Stopping process on port $port..." -ForegroundColor Cyan
        Stop-Process -Id $process -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "✅ All services stopped" -ForegroundColor Green

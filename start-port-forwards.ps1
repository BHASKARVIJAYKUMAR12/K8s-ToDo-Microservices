# Start Port Forwards for Todo App
# This script manages port-forwarding for local Kubernetes testing

Write-Host "`n🚀 Starting Todo App Port Forwards..." -ForegroundColor Green

# Kill any existing port-forwards
Write-Host "`n🧹 Cleaning up existing port-forwards..." -ForegroundColor Yellow
Get-Process kubectl -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Wait for cleanup
Start-Sleep -Seconds 2

# Start API Gateway port-forward (using 8081 to avoid conflicts)
Write-Host "📡 Starting API Gateway port-forward (localhost:8081 → api-gateway:8080)..." -ForegroundColor Blue
Start-Process powershell -WindowStyle Minimized -ArgumentList "-NoExit", "-Command", "Write-Host '🌐 API Gateway Port Forward Active' -ForegroundColor Green; Write-Host 'Port: localhost:8081 → todo-app/api-gateway-service:8080' -ForegroundColor Cyan; kubectl port-forward -n todo-app svc/api-gateway-service 8081:8080"

# Start Frontend port-forward
Write-Host "🎨 Starting Frontend port-forward (localhost:3000 → frontend:80)..." -ForegroundColor Blue
Start-Process powershell -WindowStyle Minimized -ArgumentList "-NoExit", "-Command", "Write-Host '🎨 Frontend Port Forward Active' -ForegroundColor Green; Write-Host 'Port: localhost:3000 → todo-app/frontend-service:80' -ForegroundColor Cyan; kubectl port-forward -n todo-app svc/frontend-service 3000:80"

# Wait for port-forwards to start
Write-Host "`n⏳ Waiting for port-forwards to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 4

# Test connections
Write-Host "`n=== Testing Connections ===" -ForegroundColor Cyan

Write-Host "`n🔍 API Gateway Health Check..." -NoNewline
try {
    $response = curl.exe -s http://localhost:8081/health 2>$null
    if ($response -like "*healthy*") {
        Write-Host " ✅ OK" -ForegroundColor Green
        Write-Host "   Response: $response" -ForegroundColor Gray
    } else {
        Write-Host " ⚠️  Unexpected response" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ❌ Failed" -ForegroundColor Red
}

Write-Host "`n🔍 Frontend Accessibility..." -NoNewline
try {
    $null = curl.exe -s http://localhost:3000 -o $null 2>$null
    if ($?) {
        Write-Host " ✅ OK" -ForegroundColor Green
    } else {
        Write-Host " ⚠️  Check failed" -ForegroundColor Yellow
    }
} catch {
    Write-Host " ❌ Failed" -ForegroundColor Red
}

# Display access information
Write-Host "`n=== 🌍 Access URLs ===" -ForegroundColor Green
Write-Host "Frontend:    http://localhost:3000" -ForegroundColor Cyan
Write-Host "API Gateway: http://localhost:8081" -ForegroundColor Cyan
Write-Host "API Docs:    http://localhost:8081/health" -ForegroundColor Cyan

# Display important note
Write-Host "`n=== ⚠️  Important Note ===" -ForegroundColor Yellow
Write-Host "The API Gateway is running on port 8081 (not 8080) due to port conflict." -ForegroundColor Yellow
Write-Host "Port 8080 is occupied by Apache HTTP server (httpd) on your system." -ForegroundColor Yellow

Write-Host "`n=== 🔧 Frontend API Configuration ===" -ForegroundColor Yellow
Write-Host "The frontend expects API on port 8080, but we're using 8081." -ForegroundColor Yellow
Write-Host "`nQuick fix options:" -ForegroundColor White
Write-Host "1. Browser Console: Run this in Chrome DevTools (F12):" -ForegroundColor White
Write-Host "   localStorage.setItem('API_BASE_URL', 'http://localhost:8081/api');" -ForegroundColor Gray
Write-Host "   location.reload();" -ForegroundColor Gray
Write-Host "`n2. Use browser extension like 'Requestly' to redirect 8080 → 8081" -ForegroundColor White
Write-Host "`n3. Stop Apache: Stop-Process -Name 'httpd' -Force" -ForegroundColor White
Write-Host "   Then restart with: kubectl port-forward -n todo-app svc/api-gateway-service 8080:8080" -ForegroundColor Gray

Write-Host "`n=== 📊 Port Forward Status ===" -ForegroundColor Cyan
Get-Process kubectl -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, StartTime | Format-Table -AutoSize

Write-Host "`n=== 🧪 Quick Test Commands ===" -ForegroundColor Cyan
Write-Host "# Test API Health:" -ForegroundColor White
Write-Host "curl.exe http://localhost:8081/health" -ForegroundColor Gray
Write-Host "`n# Test Registration:" -ForegroundColor White
Write-Host 'curl.exe -X POST http://localhost:8081/api/auth/register -H "Content-Type: application/json" -d "{\"username\":\"test\",\"email\":\"test@test.com\",\"password\":\"pass123\"}"' -ForegroundColor Gray
Write-Host "`n# View Pod Logs:" -ForegroundColor White
Write-Host "kubectl logs -f deployment/api-gateway -n todo-app" -ForegroundColor Gray

Write-Host "`n=== 🛑 To Stop Port Forwards ===" -ForegroundColor Red
Write-Host "Get-Process kubectl | Stop-Process -Force" -ForegroundColor Gray

Write-Host "`n✅ Port forwards are running!" -ForegroundColor Green
Write-Host "Open http://localhost:3000 in your browser to access the application.`n" -ForegroundColor Cyan

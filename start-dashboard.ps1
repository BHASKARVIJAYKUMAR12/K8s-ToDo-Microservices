# 🚀 Start Kubernetes Dashboard - Quick Script

Write-Host "`n🎨 Starting Kubernetes Dashboard..." -ForegroundColor Green

# Kill any existing kubectl proxy processes
Write-Host "`n🧹 Cleaning up old proxy processes..." -ForegroundColor Yellow
Get-Process kubectl -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Start kubectl proxy in a new window
Write-Host "🌐 Starting kubectl proxy..." -ForegroundColor Blue
Start-Process powershell -WindowStyle Normal -ArgumentList "-NoExit", "-Command", @"
Write-Host '═══════════════════════════════════════════════════════' -ForegroundColor Cyan
Write-Host '🌐 Kubernetes Proxy is Running' -ForegroundColor Green
Write-Host '═══════════════════════════════════════════════════════' -ForegroundColor Cyan
Write-Host ''
Write-Host '📊 Dashboard URL:' -ForegroundColor Yellow
Write-Host '   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/' -ForegroundColor White
Write-Host ''
Write-Host '🔑 To get access token, run in another terminal:' -ForegroundColor Yellow
Write-Host '   kubectl create token dashboard-admin -n kubernetes-dashboard --duration=24h' -ForegroundColor Gray
Write-Host ''
Write-Host '⚠️  Keep this window open! Closing it will stop the proxy.' -ForegroundColor Red
Write-Host '═══════════════════════════════════════════════════════' -ForegroundColor Cyan
Write-Host ''
kubectl proxy
"@

# Wait for proxy to start
Write-Host "⏳ Waiting for proxy to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Verify proxy is running
$proxyRunning = Get-Process kubectl -ErrorAction SilentlyContinue
if ($proxyRunning) {
    Write-Host "✅ Proxy started successfully!" -ForegroundColor Green
    
    # Test connection
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8001/api" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ Proxy is responding (Status: $($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Proxy started but not responding yet. Wait a few seconds." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Failed to start proxy. Try running manually: kubectl proxy" -ForegroundColor Red
    exit 1
}

# Generate access token
Write-Host "`n🔑 Generating access token..." -ForegroundColor Blue
$token = kubectl create token dashboard-admin -n kubernetes-dashboard --duration=24h 2>$null

if ($token) {
    Write-Host "✅ Token generated successfully!" -ForegroundColor Green
    Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "📋 COPY THIS ACCESS TOKEN:" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host $token -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    # Copy to clipboard if possible
    try {
        $token | Set-Clipboard
        Write-Host "✅ Token copied to clipboard!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Couldn't copy to clipboard. Please copy manually." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Failed to generate token. Run manually:" -ForegroundColor Yellow
    Write-Host "   kubectl create token dashboard-admin -n kubernetes-dashboard --duration=24h" -ForegroundColor Gray
}

# Display access information
Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🌍 DASHBOARD ACCESS INFORMATION" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Dashboard URL:" -ForegroundColor Yellow
Write-Host "   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/" -ForegroundColor White
Write-Host ""
Write-Host "🔐 Login Steps:" -ForegroundColor Yellow
Write-Host "   1. Open the URL above in your browser" -ForegroundColor White
Write-Host "   2. Select 'Token' authentication method" -ForegroundColor White
Write-Host "   3. Paste the token (copied above)" -ForegroundColor White
Write-Host "   4. Click 'Sign In'" -ForegroundColor White
Write-Host ""
Write-Host "📂 View Your App:" -ForegroundColor Yellow
Write-Host "   1. After login, select namespace: 'todo-app'" -ForegroundColor White
Write-Host "   2. Navigate to: Workloads → Pods" -ForegroundColor White
Write-Host "   3. See all your running pods!" -ForegroundColor White
Write-Host ""
Write-Host "🛑 To Stop Dashboard:" -ForegroundColor Red
Write-Host "   Close the kubectl proxy window or run:" -ForegroundColor White
Write-Host "   Get-Process kubectl | Stop-Process -Force" -ForegroundColor Gray
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Dashboard is ready! Open the URL in your browser." -ForegroundColor Green
Write-Host ""

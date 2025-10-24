# Quick Restart All Services Script
# Use this after updating environment variables

Write-Host "🔄 Restarting All Services with New Configuration" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

Write-Host "`n⚠️  Please stop all running services (Ctrl+C in each terminal)" -ForegroundColor Yellow
Write-Host "Then run each service manually in separate terminals:" -ForegroundColor Yellow

Write-Host "`n📝 Commands to run:" -ForegroundColor Green

Write-Host "`nTerminal 1 - User Service:" -ForegroundColor Cyan
Write-Host "cd user-service" -ForegroundColor White
Write-Host "npm run dev" -ForegroundColor White

Write-Host "`nTerminal 2 - Todo Service:" -ForegroundColor Cyan
Write-Host "cd todo-service" -ForegroundColor White
Write-Host "npm run dev" -ForegroundColor White

Write-Host "`nTerminal 3 - Notification Service:" -ForegroundColor Cyan
Write-Host "cd notification-service" -ForegroundColor White
Write-Host "npm run dev" -ForegroundColor White

Write-Host "`nTerminal 4 - API Gateway:" -ForegroundColor Cyan
Write-Host "cd api-gateway" -ForegroundColor White
Write-Host "npm run dev" -ForegroundColor White

Write-Host "`nTerminal 5 - Frontend:" -ForegroundColor Cyan
Write-Host "cd frontend" -ForegroundColor White
Write-Host "npm start" -ForegroundColor White

Write-Host "`n🌐 After all services start:" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:3000" -ForegroundColor White
Write-Host "2. Press F12 to open console" -ForegroundColor White
Write-Host "3. Run: localStorage.clear()" -ForegroundColor White
Write-Host "4. Refresh the page" -ForegroundColor White
Write-Host "5. Register a new user" -ForegroundColor White
Write-Host "6. Test creating todos - should work now! ✅" -ForegroundColor White

Write-Host "`n✅ All .env files have been updated with matching JWT secrets" -ForegroundColor Green
Write-Host "   Services will use: JWT_SECRET=local-dev-secret-key-change-in-production" -ForegroundColor Gray

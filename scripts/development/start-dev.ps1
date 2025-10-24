# 🚀 Start Todo App in Development Mode

Write-Host "🔥 Starting Todo App in Development Mode..." -ForegroundColor Green
Write-Host ""

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js is not installed. Please install Node.js 18+ first." -ForegroundColor Red
    exit 1
}

# Start databases in Docker (if not running)
Write-Host "🐳 Starting databases in Docker..." -ForegroundColor Blue
docker-compose up -d postgres redis

# Wait for databases to be ready
Write-Host "⏳ Waiting for databases to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Function to start a service in a new terminal
function Start-Service {
    param(
        [string]$ServiceName,
        [string]$Port,
        [string]$Path
    )
    
    Write-Host "🚀 Starting $ServiceName on port $Port..." -ForegroundColor Cyan
    
    # Start in new PowerShell window
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd $Path; npm install; npm run dev"
}

# Start all services
Start-Service "API Gateway" "8080" "api-gateway"
Start-Service "User Service" "3002" "user-service"
Start-Service "Todo Service" "3001" "todo-service"
Start-Service "Notification Service" "3003" "notification-service"
Start-Service "Frontend" "3000" "frontend"

Write-Host ""
Write-Host "✅ All services are starting..." -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Your application will be available at:" -ForegroundColor Yellow
Write-Host "   Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "   API Gateway: http://localhost:8080" -ForegroundColor White
Write-Host ""
Write-Host "📊 Service URLs:" -ForegroundColor Yellow
Write-Host "   User Service: http://localhost:3002" -ForegroundColor White
Write-Host "   Todo Service: http://localhost:3001" -ForegroundColor White
Write-Host "   Notification Service: http://localhost:3003" -ForegroundColor White
Write-Host ""
Write-Host "🛑 To stop all services:" -ForegroundColor Red
Write-Host "   - Close all PowerShell windows" -ForegroundColor White
Write-Host "   - Run: docker-compose down" -ForegroundColor White
Write-Host ""
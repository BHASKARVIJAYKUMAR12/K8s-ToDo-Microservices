# Local Development Startup Script for Todo Microservices
# This script starts all services in development mode with proper environment variables

Write-Host "🚀 Starting Todo Microservices - Local Development" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Check if PostgreSQL and Redis are running
Write-Host "`n📊 Checking required services..." -ForegroundColor Yellow

# Function to check if port is in use
function Test-Port {
    param($Port)
    $connection = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue
    return $connection.TcpTestSucceeded
}

# Check PostgreSQL
if (-not (Test-Port -Port 5432)) {
    Write-Host "❌ PostgreSQL is not running on port 5432" -ForegroundColor Red
    Write-Host "   Please start PostgreSQL or run: docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=password postgres:15-alpine" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ PostgreSQL is running" -ForegroundColor Green

# Check Redis
if (-not (Test-Port -Port 6379)) {
    Write-Host "❌ Redis is not running on port 6379" -ForegroundColor Red
    Write-Host "   Please start Redis or run: docker run -d -p 6379:6379 redis:7-alpine" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Redis is running" -ForegroundColor Green

Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow

# Install dependencies for all services
$services = @("api-gateway", "todo-service", "user-service", "notification-service", "frontend")

foreach ($service in $services) {
    if (Test-Path "$service\package.json") {
        Write-Host "Installing dependencies for $service..." -ForegroundColor Cyan
        Push-Location $service
        npm install --silent
        Pop-Location
    }
}

Write-Host "`n🔧 Building TypeScript services..." -ForegroundColor Yellow

# Build backend services
$backendServices = @("api-gateway", "todo-service", "user-service", "notification-service")

foreach ($service in $backendServices) {
    if (Test-Path "$service\tsconfig.json") {
        Write-Host "Building $service..." -ForegroundColor Cyan
        Push-Location $service
        npm run build
        Pop-Location
    }
}

Write-Host "`n🚀 Starting services..." -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Cyan

# Start services in background using Start-Job
Write-Host "Starting User Service on port 3002..." -ForegroundColor Green
$userJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD\user-service
    $env:NODE_ENV = "development"
    Copy-Item -Path ".env.local" -Destination ".env" -Force -ErrorAction SilentlyContinue
    npm run dev
}

Start-Sleep -Seconds 3

Write-Host "Starting Todo Service on port 3001..." -ForegroundColor Green
$todoJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD\todo-service
    $env:NODE_ENV = "development"
    Copy-Item -Path ".env.local" -Destination ".env" -Force -ErrorAction SilentlyContinue
    npm run dev
}

Start-Sleep -Seconds 3

Write-Host "Starting Notification Service on port 3003..." -ForegroundColor Green
$notificationJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD\notification-service
    $env:NODE_ENV = "development"
    Copy-Item -Path ".env.local" -Destination ".env" -Force -ErrorAction SilentlyContinue
    npm run dev
}

Start-Sleep -Seconds 3

Write-Host "Starting API Gateway on port 8080..." -ForegroundColor Green
$gatewayJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD\api-gateway
    $env:NODE_ENV = "development"
    Copy-Item -Path ".env.local" -Destination ".env" -Force -ErrorAction SilentlyContinue
    npm run dev
}

Start-Sleep -Seconds 3

Write-Host "Starting Frontend on port 3000..." -ForegroundColor Green
$frontendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD\frontend
    Copy-Item -Path ".env.local" -Destination ".env" -Force -ErrorAction SilentlyContinue
    npm start
}

Write-Host "`n✅ All services started!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "`n📋 Service URLs:" -ForegroundColor Yellow
Write-Host "  🌐 Frontend:             http://localhost:3000" -ForegroundColor Cyan
Write-Host "  🚪 API Gateway:          http://localhost:8080" -ForegroundColor Cyan
Write-Host "  📝 Todo Service:         http://localhost:3001" -ForegroundColor Cyan
Write-Host "  👤 User Service:         http://localhost:3002" -ForegroundColor Cyan
Write-Host "  📢 Notification Service: http://localhost:3003" -ForegroundColor Cyan

Write-Host "`n🔍 Health Checks:" -ForegroundColor Yellow
Write-Host "  http://localhost:8080/health" -ForegroundColor Gray
Write-Host "  http://localhost:3001/health" -ForegroundColor Gray
Write-Host "  http://localhost:3002/health" -ForegroundColor Gray
Write-Host "  http://localhost:3003/health" -ForegroundColor Gray

Write-Host "`n⚠️  To stop all services, run: .\scripts\development\stop-local.ps1" -ForegroundColor Yellow
Write-Host "    Or press Ctrl+C and run: Get-Job | Remove-Job -Force" -ForegroundColor Yellow

Write-Host "`n📊 Monitoring service logs..." -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Keep script running and show job status
try {
    while ($true) {
        Start-Sleep -Seconds 10
        $jobs = @($userJob, $todoJob, $notificationJob, $gatewayJob, $frontendJob)
        $runningCount = ($jobs | Where-Object { $_.State -eq "Running" }).Count
        
        if ($runningCount -eq 0) {
            Write-Host "`n❌ All services stopped" -ForegroundColor Red
            break
        }
        
        Write-Host "✅ $runningCount/5 services running..." -ForegroundColor Green
    }
}
finally {
    Write-Host "`n🛑 Stopping all services..." -ForegroundColor Yellow
    Get-Job | Remove-Job -Force
    Write-Host "✅ All services stopped" -ForegroundColor Green
}

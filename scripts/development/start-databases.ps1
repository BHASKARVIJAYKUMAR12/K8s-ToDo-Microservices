# Quick Start PostgreSQL and Redis for Local Development

Write-Host "🐘 Starting PostgreSQL and Redis with Docker..." -ForegroundColor Cyan

# Check if Docker is running
try {
    docker ps | Out-Null
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Start PostgreSQL
Write-Host "Starting PostgreSQL on port 5432..." -ForegroundColor Green
docker run -d `
    --name todo-postgres `
    -e POSTGRES_DB=todoapp `
    -e POSTGRES_USER=postgres `
    -e POSTGRES_PASSWORD=password `
    -p 5432:5432 `
    postgres:15-alpine 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "PostgreSQL container already exists, starting it..." -ForegroundColor Yellow
    docker start todo-postgres 2>&1 | Out-Null
}

# Start Redis
Write-Host "Starting Redis on port 6379..." -ForegroundColor Green
docker run -d `
    --name todo-redis `
    -p 6379:6379 `
    redis:7-alpine 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Redis container already exists, starting it..." -ForegroundColor Yellow
    docker start todo-redis 2>&1 | Out-Null
}

Start-Sleep -Seconds 3

Write-Host "`n✅ Services started successfully!" -ForegroundColor Green
Write-Host "   PostgreSQL: localhost:5432" -ForegroundColor Cyan
Write-Host "   Redis:      localhost:6379" -ForegroundColor Cyan
Write-Host "`nTo stop: docker stop todo-postgres todo-redis" -ForegroundColor Yellow

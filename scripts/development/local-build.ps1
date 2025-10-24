# Local Build Script for Docker Desktop Testing
# This script builds all services locally for Kubernetes testing

param(
    [Parameter(Mandatory=$false)]
    [switch]$Rebuild = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipTests = $false
)

Write-Host "🏗️ Building Todo Application for Local Kubernetes Testing..." -ForegroundColor Green

# Function to build a service
function Build-Service {
    param(
        [string]$ServiceName,
        [string]$ServicePath
    )
    
    Write-Host "`n🔧 Building $ServiceName..." -ForegroundColor Blue
    
    if (Test-Path $ServicePath) {
        Push-Location $ServicePath
        
        # Build Docker image with local tag
        $localTag = "todo-app/$ServiceName`:local"
        
        if ($Rebuild) {
            Write-Host "Rebuilding $ServiceName (no cache)..." -ForegroundColor Yellow
            docker build --no-cache -t $localTag .
        } else {
            docker build -t $localTag .
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $ServiceName built successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to build $ServiceName" -ForegroundColor Red
            Pop-Location
            exit 1
        }
        
        Pop-Location
    } else {
        Write-Host "❌ Service directory not found: $ServicePath" -ForegroundColor Red
        exit 1
    }
}

# Services to build
$services = @{
    "frontend" = "frontend"
    "api-gateway" = "api-gateway"
    "todo-service" = "todo-service"
    "user-service" = "user-service"
    "notification-service" = "notification-service"
}

# Build each service
foreach ($service in $services.GetEnumerator()) {
    Build-Service -ServiceName $service.Key -ServicePath $service.Value
}

# Verify images were built
Write-Host "`n📋 Verifying built images..." -ForegroundColor Blue
docker images todo-app/*

# Optional: Run basic tests
if (-not $SkipTests) {
    Write-Host "`n🧪 Running basic container tests..." -ForegroundColor Blue
    
    foreach ($service in $services.Keys) {
        $imageName = "todo-app/$service`:local"
        Write-Host "Testing $imageName..." -ForegroundColor Yellow
        
        # Test that container starts without errors
        $containerId = docker run -d $imageName
        Start-Sleep -Seconds 3
        
        $status = docker ps --filter "id=$containerId" --format "{{.Status}}"
        if ($status -like "*Up*") {
            Write-Host "✅ $service container starts successfully" -ForegroundColor Green
            docker stop $containerId > $null
            docker rm $containerId > $null
        } else {
            Write-Host "⚠️ $service container may have issues" -ForegroundColor Yellow
            docker logs $containerId
            docker stop $containerId > $null
            docker rm $containerId > $null
        }
    }
}

Write-Host "`n🎉 Local build completed successfully!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: .\scripts\development\deploy-local-k8s.ps1" -ForegroundColor White
Write-Host "2. Test your application locally" -ForegroundColor White
Write-Host "3. When ready, deploy to GKE with .\scripts\deployment\deploy-production.ps1" -ForegroundColor White

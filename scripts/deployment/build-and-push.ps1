# PowerShell script to build and push all Docker images to Google Container Registry
# Usage: .\build-and-push.ps1 YOUR_PROJECT_ID

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId
)

Write-Host "🚀 Building and pushing Todo App images to GCR..." -ForegroundColor Green

# Set the project ID
$GCR_PREFIX = "gcr.io/$ProjectId"

# Configure Docker to use gcloud credentials
Write-Host "📋 Configuring Docker authentication..." -ForegroundColor Yellow
gcloud auth configure-docker

# Services to build
$services = @(
    "frontend",
    "api-gateway", 
    "todo-service",
    "user-service",
    "notification-service"
)

foreach ($service in $services) {
    Write-Host "`n🔨 Building $service..." -ForegroundColor Cyan
    
    # Build the image
    docker build -t "$GCR_PREFIX/$service`:latest" "./$service"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Build successful for $service" -ForegroundColor Green
        
        # Push the image
        Write-Host "📤 Pushing $service to GCR..." -ForegroundColor Cyan
        docker push "$GCR_PREFIX/$service`:latest"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Push successful for $service" -ForegroundColor Green
        } else {
            Write-Host "❌ Push failed for $service" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Build failed for $service" -ForegroundColor Red
    }
}

Write-Host "`n🎉 All images processed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update k8s-specifications/ with your GCR image names" -ForegroundColor White
Write-Host "2. Run: kubectl apply -f k8s-specifications/" -ForegroundColor White
Write-Host "3. Check status: kubectl get all" -ForegroundColor White
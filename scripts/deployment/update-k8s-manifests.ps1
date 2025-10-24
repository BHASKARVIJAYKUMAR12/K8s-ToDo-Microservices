# PowerShell script to update Kubernetes manifests with GCR image names
# Usage: .\update-k8s-manifests.ps1 YOUR_PROJECT_ID

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId
)

Write-Host "🔄 Updating Kubernetes manifests for GCR images..." -ForegroundColor Green

$GCR_PREFIX = "gcr.io/$ProjectId"

# Backup original files
$backupDir = "k8s-specifications-backup"
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir
    Copy-Item "k8s-specifications\*" $backupDir -Recurse
    Write-Host "✅ Backup created in $backupDir" -ForegroundColor Green
}

# Update image references in deployment files
$deployments = @{
    "frontend-deployment.yaml" = "frontend:latest"
    "api-gateway-deployment.yaml" = "api-gateway:latest"
    "todo-service-deployment.yaml" = "todo-service:latest"
    "user-service-deployment.yaml" = "user-service:latest"
    "notification-service-deployment.yaml" = "notification-service:latest"
}

foreach ($file in $deployments.Keys) {
    $filePath = "k8s-specifications\$file"
    $imageName = $deployments[$file]
    $gcrImage = "$GCR_PREFIX/$imageName"
    
    if (Test-Path $filePath) {
        Write-Host "📝 Updating $file..." -ForegroundColor Cyan
        
        # Read file content
        $content = Get-Content $filePath -Raw
        
        # Replace image reference
        $updatedContent = $content -replace "image: $imageName", "image: $gcrImage"
        
        # Write back to file
        Set-Content -Path $filePath -Value $updatedContent
        
        Write-Host "✅ Updated image reference to $gcrImage" -ForegroundColor Green
    } else {
        Write-Host "⚠️ File not found: $filePath" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 All manifest files updated!" -ForegroundColor Green
Write-Host "Updated image references to use: $GCR_PREFIX" -ForegroundColor White
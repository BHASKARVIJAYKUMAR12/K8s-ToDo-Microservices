# Build and Deploy Script for Windows/Docker Desktop
# Complete automation for building and deploying to local Kubernetes

Write-Host "🚀 Todo Microservices - Build and Deploy" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# Configuration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$NAMESPACE = "todo-app"
$SERVICES = @("frontend", "api-gateway", "user-service", "todo-service", "notification-service")

# Function to print colored messages
function Write-Info {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param($Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check Docker
    try {
        docker version | Out-Null
    } catch {
        Write-ErrorMsg "Docker is not installed or not running"
        exit 1
    }
    
    # Check kubectl
    try {
        kubectl version --client | Out-Null
    } catch {
        Write-ErrorMsg "kubectl is not installed"
        exit 1
    }
    
    # Check Kubernetes cluster
    try {
        kubectl cluster-info | Out-Null
    } catch {
        Write-ErrorMsg "Kubernetes cluster is not accessible. Is Docker Desktop Kubernetes enabled?"
        exit 1
    }
    
    Write-Success "All prerequisites met"
}

# Clean up old images
function Remove-OldImages {
    Write-Info "Cleaning up old Docker images..."
    
    # Remove old todo app images
    docker images | Select-String "todo-|api-gateway|frontend|user-service|notification-service" | ForEach-Object {
        $imageLine = $_ -replace '\s+', ' '
        $parts = $imageLine -split ' '
        $imageId = $parts[2]
        if ($imageId -and $imageId -ne "IMAGE") {
            Write-Info "Removing image: $imageId"
            docker rmi -f $imageId 2>$null
        }
    }
    
    # Remove dangling images
    docker image prune -f | Out-Null
    
    Write-Success "Old images cleaned up"
}

# Build Docker images
function Build-Images {
    Write-Info "Building Docker images..."
    
    foreach ($service in $SERVICES) {
        Write-Info "Building $service..."
        
        $servicePath = Join-Path $PROJECT_ROOT $service
        Push-Location $servicePath
        
        try {
            if ($service -eq "frontend") {
                # Build frontend with environment variable
                docker build -t "${service}:latest" -t "${service}:dev" --build-arg REACT_APP_API_URL="/api" .
            } else {
                docker build -t "${service}:latest" -t "${service}:dev" .
            }
            
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed for $service"
            }
            
            Write-Success "$service image built successfully"
        } catch {
            Write-ErrorMsg "Failed to build $service : $_"
            Pop-Location
            exit 1
        }
        
        Pop-Location
    }
    
    Write-Success "All images built successfully"
}

# Create namespace
function New-K8sNamespace {
    Write-Info "Creating namespace: $NAMESPACE..."
    
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f - | Out-Null
    
    Write-Success "Namespace ready"
}

# Deploy to Kubernetes
function Deploy-ToKubernetes {
    Write-Info "Deploying to Kubernetes..."
    
    $K8S_DIR = Join-Path $PROJECT_ROOT "k8s\simple"
    
    # Deploy infrastructure
    Write-Info "Deploying databases..."
    kubectl apply -f "$K8S_DIR\postgres-deployment.yaml" | Out-Null
    kubectl apply -f "$K8S_DIR\redis-deployment.yaml" | Out-Null
    
    # Wait for databases
    Write-Info "Waiting for databases to be ready..."
    Start-Sleep -Seconds 20
    
    # Deploy backend services
    Write-Info "Deploying backend services..."
    kubectl apply -f "$K8S_DIR\user-service-deployment.yaml" | Out-Null
    kubectl apply -f "$K8S_DIR\todo-service-deployment.yaml" | Out-Null
    kubectl apply -f "$K8S_DIR\notification-service-deployment.yaml" | Out-Null
    
    Start-Sleep -Seconds 15
    
    # Deploy API Gateway
    Write-Info "Deploying API Gateway..."
    kubectl apply -f "$K8S_DIR\api-gateway-deployment.yaml" | Out-Null
    
    Start-Sleep -Seconds 10
    
    # Deploy Frontend
    Write-Info "Deploying Frontend..."
    kubectl apply -f "$K8S_DIR\frontend-deployment.yaml" | Out-Null
    
    # Deploy Ingress (optional)
    if (Test-Path "$K8S_DIR\ingress.yaml") {
        Write-Info "Deploying Ingress..."
        kubectl apply -f "$K8S_DIR\ingress.yaml" 2>$null | Out-Null
    }
    
    Write-Success "All services deployed"
}

# Check deployment status
function Test-Deployment {
    Write-Info "Checking deployment status..."
    
    Write-Host "`nPods:" -ForegroundColor Cyan
    kubectl get pods -n $NAMESPACE
    
    Write-Host "`nServices:" -ForegroundColor Cyan
    kubectl get services -n $NAMESPACE
    
    Write-Info "Waiting for all pods to be ready (this may take a few minutes)..."
    
    $maxWaitTime = 300 # 5 minutes
    $waitedTime = 0
    $allReady = $false
    
    while ($waitedTime -lt $maxWaitTime -and -not $allReady) {
        $pods = kubectl get pods -n $NAMESPACE -o json | ConvertFrom-Json
        $totalPods = $pods.items.Count
        $readyPods = ($pods.items | Where-Object { 
            $_.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" }
        }).Count
        
        Write-Host "`rReady: $readyPods/$totalPods pods" -NoNewline -ForegroundColor Yellow
        
        if ($readyPods -eq $totalPods -and $totalPods -gt 0) {
            $allReady = $true
        } else {
            Start-Sleep -Seconds 5
            $waitedTime += 5
        }
    }
    
    Write-Host ""
    
    if ($allReady) {
        Write-Success "All pods are ready!"
    } else {
        Write-Warning "Some pods are not ready yet. Check with: kubectl get pods -n $NAMESPACE"
    }
}

# Setup port forwarding
function Start-PortForward {
    Write-Info "Setting up port forwarding..."
    
    Write-Host "`nTo access your application, run these commands in separate terminals:" -ForegroundColor Yellow
    Write-Host "  kubectl port-forward svc/frontend-service 3000:80 -n $NAMESPACE" -ForegroundColor White
    Write-Host "  kubectl port-forward svc/api-gateway-service 8080:8080 -n $NAMESPACE" -ForegroundColor White
    
    Write-Host "`nOr use the start-port-forwards.ps1 script" -ForegroundColor Cyan
}

# Display access information
function Show-AccessInfo {
    Write-Success "`n✅ Deployment completed successfully!" 
    Write-Host "==========================================" -ForegroundColor Cyan
    
    Write-Info "Access Information:"
    Write-Host "  After port-forwarding:"
    Write-Host "    Frontend:    http://localhost:3000" -ForegroundColor Green
    Write-Host "    API Gateway: http://localhost:8080" -ForegroundColor Green
    
    Write-Host "`n📋 Useful Commands:" -ForegroundColor Yellow
    Write-Host "  kubectl get pods -n $NAMESPACE"
    Write-Host "  kubectl get services -n $NAMESPACE"
    Write-Host "  kubectl logs -f POD_NAME -n $NAMESPACE"
    Write-Host "  kubectl describe pod POD_NAME -n $NAMESPACE"
    Write-Host "  kubectl delete namespace $NAMESPACE  # To clean up"
}

# Main execution
function Main {
    try {
        Write-Info "Starting deployment process...`n"
        
        Test-Prerequisites
        Remove-OldImages
        Build-Images
        New-K8sNamespace
        Deploy-ToKubernetes
        Test-Deployment
        Start-PortForward
        Show-AccessInfo
        
    } catch {
        Write-ErrorMsg "Deployment failed: $_"
        exit 1
    }
}

# Run main
Main

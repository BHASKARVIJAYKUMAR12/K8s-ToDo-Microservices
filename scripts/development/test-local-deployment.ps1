# Local Deployment Testing Script
# This script tests your local Kubernetes deployment

param(
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

Write-Host "🧪 Testing Local Kubernetes Deployment..." -ForegroundColor Green

# Function to test HTTP endpoint
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [int]$ExpectedStatusCode = 200,
        [int]$TimeoutSeconds = 30
    )
    
    Write-Host "`nTesting $Name..." -ForegroundColor Blue
    Write-Host "URL: $Url" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSeconds -UseBasicParsing
        if ($response.StatusCode -eq $ExpectedStatusCode) {
            Write-Host "✅ $Name - Status: $($response.StatusCode)" -ForegroundColor Green
            if ($Verbose) {
                Write-Host "Response Length: $($response.Content.Length) bytes" -ForegroundColor Gray
            }
            return $true
        } else {
            Write-Host "⚠️ $Name - Unexpected Status: $($response.StatusCode)" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "❌ $Name - Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test service connectivity within cluster
function Test-ServiceConnectivity {
    Write-Host "`n🔗 Testing inter-service connectivity..." -ForegroundColor Blue
    
    # Create a test pod for internal testing
    $testPodManifest = @"
apiVersion: v1
kind: Pod
metadata:
  name: connectivity-test
  namespace: todo-app
spec:
  containers:
  - name: test
    image: curlimages/curl:latest
    command: ["sleep", "300"]
  restartPolicy: Never
"@
    
    $testPodManifest | kubectl apply -f -
    
    # Wait for pod to be ready
    kubectl wait --for=condition=Ready pod/connectivity-test -n todo-app --timeout=60s
    
    # Test internal service connectivity
    $services = @(
        "user-service:3002",
        "todo-service:3001", 
        "notification-service:3003",
        "api-gateway-service:8080",
        "postgres-service:5432",
        "redis-service:6379"
    )
    
    foreach ($service in $services) {
        $serviceName = $service.Split(':')[0]
        $port = $service.Split(':')[1]
        
        Write-Host "Testing $serviceName..." -ForegroundColor Yellow
        $result = kubectl exec connectivity-test -n todo-app -- nc -z $serviceName $port 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $serviceName is reachable" -ForegroundColor Green
        } else {
            Write-Host "❌ $serviceName is not reachable" -ForegroundColor Red
        }
    }
    
    # Clean up test pod
    kubectl delete pod connectivity-test -n todo-app --ignore-not-found=true
}

# Check if deployment exists
Write-Host "📋 Checking deployment status..." -ForegroundColor Blue
$deployments = kubectl get deployments -n todo-app --no-headers 2>$null
if (-not $deployments) {
    Write-Host "❌ No deployments found in todo-app namespace" -ForegroundColor Red
    Write-Host "Run .\scripts\development\deploy-local-k8s.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Check pod status
Write-Host "`n📊 Pod Status:" -ForegroundColor Cyan
kubectl get pods -n todo-app

# Check service status
Write-Host "`n🌐 Service Status:" -ForegroundColor Cyan
kubectl get services -n todo-app

# Wait for services to be fully ready
Write-Host "`n⏳ Waiting for services to be ready..." -ForegroundColor Yellow
$maxWaitTime = 300 # 5 minutes
$waitTime = 0
$interval = 10

do {
    $readyPods = kubectl get pods -n todo-app --no-headers | Where-Object { $_ -match "Running" -and $_ -match "1/1" }
    $totalPods = kubectl get pods -n todo-app --no-headers | Measure-Object | Select-Object -ExpandProperty Count
    $readyCount = if ($readyPods) { ($readyPods | Measure-Object).Count } else { 0 }
    
    Write-Host "Ready pods: $readyCount/$totalPods" -ForegroundColor Yellow
    
    if ($readyCount -eq $totalPods -and $totalPods -gt 0) {
        Write-Host "✅ All pods are ready!" -ForegroundColor Green
        break
    }
    
    Start-Sleep -Seconds $interval
    $waitTime += $interval
    
    if ($waitTime -ge $maxWaitTime) {
        Write-Host "⚠️ Timeout waiting for pods to be ready" -ForegroundColor Yellow
        break
    }
} while ($true)

# Test service connectivity
Test-ServiceConnectivity

# Set up port forwarding for testing
Write-Host "`n🔌 Setting up port forwarding..." -ForegroundColor Blue

# Start port forwarding in background jobs
$frontendJob = Start-Job -ScriptBlock { 
    kubectl port-forward -n todo-app svc/frontend-service 3000:80 
}

$apiJob = Start-Job -ScriptBlock { 
    kubectl port-forward -n todo-app svc/api-gateway-service 8080:8080 
}

# Wait a moment for port forwarding to establish
Start-Sleep -Seconds 5

# Test external endpoints
Write-Host "`n🌍 Testing external access..." -ForegroundColor Blue

$testResults = @()

# Test Frontend
$testResults += Test-Endpoint -Name "Frontend (Home Page)" -Url "http://localhost:3000"

# Test API Gateway Health
$testResults += Test-Endpoint -Name "API Gateway (Health)" -Url "http://localhost:8080/health"

# Test API Gateway Version (if available)
$testResults += Test-Endpoint -Name "API Gateway (Version)" -Url "http://localhost:8080/api/version" -ExpectedStatusCode 200

# Test User Service via API Gateway
try {
    # Try to register a test user
    $testUser = @{
        username = "testuser"
        email = "test@example.com" 
        password = "testpass123"
    } | ConvertTo-Json
    
    $registerResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/auth/register" -Method POST -Body $testUser -ContentType "application/json" -UseBasicParsing -TimeoutSec 10
    if ($registerResponse.StatusCode -eq 201 -or $registerResponse.StatusCode -eq 200) {
        Write-Host "✅ User Registration API - Status: $($registerResponse.StatusCode)" -ForegroundColor Green
        $testResults += $true
    } else {
        Write-Host "⚠️ User Registration API - Status: $($registerResponse.StatusCode)" -ForegroundColor Yellow
        $testResults += $false
    }
} catch {
    if ($_.Exception.Message -match "409" -or $_.Exception.Message -match "already exists") {
        Write-Host "✅ User Registration API - User already exists (expected)" -ForegroundColor Green
        $testResults += $true
    } else {
        Write-Host "❌ User Registration API - Error: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += $false
    }
}

# Stop port forwarding jobs
Stop-Job $frontendJob, $apiJob
Remove-Job $frontendJob, $apiJob

# Summary
Write-Host "`n📊 Test Summary:" -ForegroundColor Cyan
$successCount = ($testResults | Where-Object { $_ -eq $true }).Count
$totalTests = $testResults.Count

Write-Host "Tests Passed: $successCount/$totalTests" -ForegroundColor $(if ($successCount -eq $totalTests) { "Green" } else { "Yellow" })

if ($successCount -eq $totalTests) {
    Write-Host "`n🎉 All tests passed! Your application is ready for GKE deployment." -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Some tests failed. Please check the logs and fix issues before GKE deployment." -ForegroundColor Yellow
}

# Provide helpful commands
Write-Host "`n🔧 Helpful Commands:" -ForegroundColor Cyan
Write-Host "View logs: kubectl logs -f deployment/DEPLOYMENT-NAME -n todo-app" -ForegroundColor White
Write-Host "Port forward: kubectl port-forward -n todo-app svc/frontend-service 3000:80" -ForegroundColor White
Write-Host "Access frontend: http://localhost:3000" -ForegroundColor White
Write-Host "Access API: http://localhost:8080" -ForegroundColor White
Write-Host "Clean up: kubectl delete namespace todo-app" -ForegroundColor White

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Test the application manually at http://localhost:3000" -ForegroundColor White
Write-Host "2. Verify all features work as expected" -ForegroundColor White  
Write-Host "3. When satisfied, deploy to GKE: .\scripts\deployment\deploy-production.ps1" -ForegroundColor White
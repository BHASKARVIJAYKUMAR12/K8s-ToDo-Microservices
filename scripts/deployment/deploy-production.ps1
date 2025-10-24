# Complete Production Deployment Script for GKE
# This script deploys the entire production-ready Todo Application to GKE

param(
    [Parameter(Mandatory=$true)]
    [string]$PROJECT_ID,
    
    [Parameter(Mandatory=$true)]
    [string]$DOMAIN_NAME,
    
    [Parameter(Mandatory=$false)]
    [string]$CLUSTER_NAME = "todo-app-cluster",
    
    [Parameter(Mandatory=$false)]
    [string]$REGION = "us-central1",
    
    [Parameter(Mandatory=$false)]
    [string]$EMAIL = "admin@$DOMAIN_NAME",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipClusterCreation,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipImageBuild,
    
    [Parameter(Mandatory=$false)]
    [switch]$ProductionMode = $true
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting complete production deployment to GKE..." -ForegroundColor Green
Write-Host "Project ID: $PROJECT_ID" -ForegroundColor Yellow
Write-Host "Domain: $DOMAIN_NAME" -ForegroundColor Yellow
Write-Host "Cluster: $CLUSTER_NAME" -ForegroundColor Yellow
Write-Host "Region: $REGION" -ForegroundColor Yellow

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "`n🔍 Checking prerequisites..." -ForegroundColor Blue
    
    $tools = @("gcloud", "kubectl", "helm", "docker")
    foreach ($tool in $tools) {
        if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
            throw "$tool is not installed or not in PATH!"
        }
        Write-Host "✅ $tool is available" -ForegroundColor Green
    }
    
    # Check if logged into gcloud
    $currentProject = gcloud config get-value project 2>$null
    if (-not $currentProject) {
        Write-Host "⚠️ Please login to gcloud first: gcloud auth login" -ForegroundColor Yellow
        throw "Not authenticated with gcloud"
    }
    
    Write-Host "✅ All prerequisites met" -ForegroundColor Green
}

# Function to create GKE cluster
function New-ProductionCluster {
    if ($SkipClusterCreation) {
        Write-Host "`n⏭️ Skipping cluster creation..." -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n🏗️ Creating production GKE cluster..." -ForegroundColor Blue
    
    # Enable required APIs
    $apis = @(
        "container.googleapis.com",
        "containerregistry.googleapis.com",
        "secretmanager.googleapis.com",
        "monitoring.googleapis.com",
        "logging.googleapis.com"
    )
    
    foreach ($api in $apis) {
        Write-Host "Enabling $api..." -ForegroundColor Yellow
        gcloud services enable $api --project=$PROJECT_ID
    }
    
    # Create Autopilot cluster (recommended for production)
    Write-Host "Creating GKE Autopilot cluster..." -ForegroundColor Green
    gcloud container clusters create-auto $CLUSTER_NAME `
        --region $REGION `
        --project $PROJECT_ID `
        --release-channel rapid `
        --enable-network-policy `
        --enable-private-nodes `
        --workload-pool=$PROJECT_ID.svc.id.goog
    
    # Get cluster credentials
    gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID
    
    Write-Host "✅ Cluster created successfully" -ForegroundColor Green
}

# Function to build and push images
function Build-ApplicationImages {
    if ($SkipImageBuild) {
        Write-Host "`n⏭️ Skipping image build..." -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n🔧 Building and pushing application images..." -ForegroundColor Blue
    
    # Configure Docker for GCR
    gcloud auth configure-docker --quiet
    
    $services = @("frontend", "api-gateway", "todo-service", "user-service", "notification-service")
    
    foreach ($service in $services) {
        Write-Host "Building $service..." -ForegroundColor Yellow
        
        # Build Docker image
        docker build -t "gcr.io/$PROJECT_ID/$service`:latest" "$service/"
        
        # Push to GCR
        docker push "gcr.io/$PROJECT_ID/$service`:latest"
        
        Write-Host "✅ $service built and pushed" -ForegroundColor Green
    }
}

# Function to update Kubernetes manifests with project ID
function Update-KubernetesManifests {
    Write-Host "`n📝 Updating Kubernetes manifests..." -ForegroundColor Blue
    
    $manifestFiles = Get-ChildItem -Path "k8s-specifications/*.yaml" -Recurse
    
    foreach ($file in $manifestFiles) {
        $content = Get-Content $file.FullName -Raw
        $content = $content -replace "PROJECT_ID", $PROJECT_ID
        $content = $content -replace "gcr.io/PROJECT_ID/", "gcr.io/$PROJECT_ID/"
        Set-Content -Path $file.FullName -Value $content
        Write-Host "Updated $($file.Name)" -ForegroundColor Green
    }
    
    # Update ingress manifest with domain
    $ingressFile = "k8s-specifications/production-ingress.yaml"
    if (Test-Path $ingressFile) {
        $content = Get-Content $ingressFile -Raw
        $content = $content -replace "DOMAIN_NAME", $DOMAIN_NAME
        Set-Content -Path $ingressFile -Value $content
        Write-Host "Updated ingress with domain: $DOMAIN_NAME" -ForegroundColor Green
    }
}

# Function to deploy secrets
function Deploy-Secrets {
    Write-Host "`n🔐 Setting up production secrets..." -ForegroundColor Blue
    
    # Run secrets setup script
    .\setup-secrets.ps1 -PROJECT_ID $PROJECT_ID -CLUSTER_NAME $CLUSTER_NAME -REGION $REGION
    
    # Install External Secrets Operator
    Write-Host "Installing External Secrets Operator..." -ForegroundColor Yellow
    helm repo add external-secrets https://charts.external-secrets.io
    helm repo update
    
    helm upgrade --install external-secrets external-secrets/external-secrets `
        --namespace external-secrets-system `
        --create-namespace `
        --set installCRDs=true
    
    # Wait for External Secrets to be ready
    kubectl wait --namespace external-secrets-system --for=condition=ready pod --selector=app.kubernetes.io/name=external-secrets --timeout=300s
    
    # Apply secret manifests
    kubectl apply -f k8s-specifications/external-secrets-sa.yaml
    kubectl apply -f k8s-specifications/production-secrets.yaml
    
    Write-Host "✅ Secrets configured" -ForegroundColor Green
}

# Function to deploy HTTPS/TLS
function Deploy-TLS {
    Write-Host "`n🔒 Setting up HTTPS/TLS..." -ForegroundColor Blue
    
    # Run HTTPS setup script
    .\setup-https.ps1 -PROJECT_ID $PROJECT_ID -DOMAIN_NAME $DOMAIN_NAME -CLUSTER_NAME $CLUSTER_NAME -REGION $REGION -EMAIL $EMAIL
    
    Write-Host "✅ HTTPS/TLS configured" -ForegroundColor Green
}

# Function to deploy monitoring
function Deploy-Monitoring {
    Write-Host "`n📊 Setting up monitoring stack..." -ForegroundColor Blue
    
    # Run monitoring setup script
    .\setup-monitoring.ps1 -PROJECT_ID $PROJECT_ID -CLUSTER_NAME $CLUSTER_NAME -REGION $REGION
    
    # Apply monitoring configurations
    kubectl apply -f monitoring/prometheus-config.yaml
    kubectl apply -f monitoring/grafana-dashboards.yaml
    
    Write-Host "✅ Monitoring stack deployed" -ForegroundColor Green
}

# Function to deploy application
function Deploy-Application {
    Write-Host "`n🚀 Deploying application services..." -ForegroundColor Blue
    
    # Deploy in order of dependencies
    $deploymentOrder = @(
        "postgres-deployment.yaml",
        "redis-deployment.yaml",
        "user-service-deployment.yaml",
        "todo-service-deployment.yaml", 
        "notification-service-deployment.yaml",
        "api-gateway-deployment.yaml",
        "frontend-deployment.yaml"
    )
    
    foreach ($manifest in $deploymentOrder) {
        $manifestPath = "k8s-specifications/$manifest"
        if (Test-Path $manifestPath) {
            Write-Host "Deploying $manifest..." -ForegroundColor Yellow
            kubectl apply -f $manifestPath
            
            # Wait for deployment to be ready
            $deploymentName = (Get-Content $manifestPath | Select-String "name:" | Select-Object -First 2 | Select-Object -Last 1).ToString().Split(":")[1].Trim()
            if ($deploymentName -and $deploymentName -ne "app-secrets") {
                Write-Host "Waiting for $deploymentName to be ready..." -ForegroundColor Yellow
                kubectl wait --for=condition=available --timeout=300s deployment/$deploymentName 2>$null
            }
        }
    }
    
    Write-Host "✅ Application deployed" -ForegroundColor Green
}

# Function to deploy ingress and networking
function Deploy-Networking {
    Write-Host "`n🌐 Setting up networking and ingress..." -ForegroundColor Blue
    
    # Apply network policies
    if (Test-Path "k8s-specifications/network-policies.yaml") {
        kubectl apply -f k8s-specifications/network-policies.yaml
    }
    
    # Apply production ingress
    if (Test-Path "k8s-specifications/production-ingress.yaml") {
        kubectl apply -f k8s-specifications/production-ingress.yaml
    }
    
    # Get external IP
    Write-Host "Getting external IP address..." -ForegroundColor Yellow
    do {
        Start-Sleep -Seconds 10
        $externalIP = kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($externalIP) {
            Write-Host "✅ External IP: $externalIP" -ForegroundColor Green
            break
        }
        Write-Host "⏳ Waiting for external IP..." -ForegroundColor Yellow
    } while ($true)
    
    Write-Host "✅ Networking configured" -ForegroundColor Green
    return $externalIP
}

# Function to verify deployment
function Test-Deployment {
    Write-Host "`n✅ Verifying deployment..." -ForegroundColor Blue
    
    # Check pod status
    Write-Host "Pod Status:" -ForegroundColor Yellow
    kubectl get pods -o wide
    
    # Check services
    Write-Host "`nService Status:" -ForegroundColor Yellow
    kubectl get services
    
    # Check ingress
    Write-Host "`nIngress Status:" -ForegroundColor Yellow
    kubectl get ingress
    
    # Check certificates
    Write-Host "`nCertificate Status:" -ForegroundColor Yellow
    kubectl get certificates
    
    # Check HPA
    Write-Host "`nHPA Status:" -ForegroundColor Yellow
    kubectl get hpa
    
    # Check secrets
    Write-Host "`nSecret Status:" -ForegroundColor Yellow
    kubectl get secrets
    
    Write-Host "✅ Deployment verification completed" -ForegroundColor Green
}

# Main execution flow
try {
    Write-Host "📋 PRODUCTION DEPLOYMENT CHECKLIST" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    # Step 1: Prerequisites
    Test-Prerequisites
    
    # Step 2: Set project
    gcloud config set project $PROJECT_ID
    
    # Step 3: Create cluster
    New-ProductionCluster
    
    # Step 4: Build images
    Build-ApplicationImages
    
    # Step 5: Update manifests
    Update-KubernetesManifests
    
    # Step 6: Deploy secrets
    Deploy-Secrets
    
    # Step 7: Deploy TLS
    Deploy-TLS
    
    # Step 8: Deploy monitoring
    Deploy-Monitoring
    
    # Step 9: Deploy application
    Deploy-Application
    
    # Step 10: Setup networking
    $externalIP = Deploy-Networking
    
    # Step 11: Verify deployment
    Test-Deployment
    
    Write-Host "`n🎉 PRODUCTION DEPLOYMENT COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host "`n📊 Deployment Summary:" -ForegroundColor Cyan
    Write-Host "✅ GKE cluster created and configured" -ForegroundColor Green
    Write-Host "✅ Docker images built and pushed to GCR" -ForegroundColor Green
    Write-Host "✅ Production secrets configured with Google Secret Manager" -ForegroundColor Green
    Write-Host "✅ HTTPS/TLS certificates configured with Let's Encrypt" -ForegroundColor Green
    Write-Host "✅ Monitoring stack deployed (Prometheus, Grafana, Jaeger)" -ForegroundColor Green
    Write-Host "✅ Application services deployed with auto-scaling" -ForegroundColor Green
    Write-Host "✅ Network policies and security hardening applied" -ForegroundColor Green
    
    Write-Host "`n🌍 Access Information:" -ForegroundColor Cyan
    Write-Host "Frontend: https://$DOMAIN_NAME" -ForegroundColor White
    Write-Host "API: https://api.$DOMAIN_NAME" -ForegroundColor White
    Write-Host "External IP: $externalIP" -ForegroundColor White
    
    Write-Host "`n📊 Monitoring Access:" -ForegroundColor Cyan
    Write-Host "Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80" -ForegroundColor White
    Write-Host "Prometheus: kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090" -ForegroundColor White
    Write-Host "Jaeger: kubectl port-forward -n monitoring svc/jaeger-query 16686:16686" -ForegroundColor White
    
    Write-Host "`n⚠️ Important Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Point your DNS records for $DOMAIN_NAME and api.$DOMAIN_NAME to IP: $externalIP" -ForegroundColor White
    Write-Host "2. Wait for TLS certificates to be issued (check: kubectl get certificates)" -ForegroundColor White
    Write-Host "3. Test your application at https://$DOMAIN_NAME" -ForegroundColor White
    Write-Host "4. Set up monitoring alerts and notifications" -ForegroundColor White
    Write-Host "5. Configure backup and disaster recovery procedures" -ForegroundColor White
    
} catch {
    Write-Host "`n❌ DEPLOYMENT FAILED!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nCheck the logs above for details." -ForegroundColor Yellow
    exit 1
}
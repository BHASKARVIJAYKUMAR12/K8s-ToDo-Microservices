# Complete GKE Deployment Script for Todo App
# Usage: .\deploy-to-gke.ps1 YOUR_PROJECT_ID

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    [string]$ClusterName = "todo-app-cluster",
    [string]$Region = "us-central1"
)

Write-Host "🚀 Starting GKE deployment for Todo App..." -ForegroundColor Green
Write-Host "Project ID: $ProjectId" -ForegroundColor White
Write-Host "Cluster: $ClusterName" -ForegroundColor White
Write-Host "Region: $Region" -ForegroundColor White

# Step 1: Verify prerequisites
Write-Host "`n🔍 Checking prerequisites..." -ForegroundColor Yellow
kubectl version --client
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ kubectl not found. Please install kubectl first." -ForegroundColor Red
    exit 1
}

gcloud version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ gcloud CLI not found. Please install Google Cloud SDK first." -ForegroundColor Red
    exit 1
}

# Step 2: Set project and authenticate
Write-Host "`n🔐 Setting up GCP project..." -ForegroundColor Yellow
gcloud config set project $ProjectId
gcloud auth login

# Step 3: Enable APIs
Write-Host "`n📡 Enabling required APIs..." -ForegroundColor Yellow
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Step 4: Connect to cluster (assume cluster exists)
Write-Host "`n🔗 Connecting to GKE cluster..." -ForegroundColor Yellow
gcloud container clusters get-credentials $ClusterName --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to connect to cluster. Please ensure cluster exists." -ForegroundColor Red
    Write-Host "Create cluster with:" -ForegroundColor Yellow
    Write-Host "gcloud container clusters create $ClusterName --region $Region --num-nodes 2 --machine-type e2-standard-2" -ForegroundColor White
    exit 1
}

# Step 5: Build and push images
Write-Host "`n🏗️ Building and pushing Docker images..." -ForegroundColor Yellow
& ".\build-and-push.ps1" $ProjectId

# Step 6: Update K8s manifests
Write-Host "`n📝 Updating Kubernetes manifests..." -ForegroundColor Yellow
& ".\update-k8s-manifests.ps1" $ProjectId

# Step 7: Deploy to Kubernetes
Write-Host "`n🚀 Deploying to Kubernetes..." -ForegroundColor Yellow
kubectl apply -f k8s-specifications/

# Step 8: Wait for deployments
Write-Host "`n⏳ Waiting for deployments to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
kubectl rollout status deployment/postgres
kubectl rollout status deployment/redis
kubectl rollout status deployment/user-service
kubectl rollout status deployment/todo-service
kubectl rollout status deployment/notification-service
kubectl rollout status deployment/api-gateway
kubectl rollout status deployment/frontend

# Step 9: Show status
Write-Host "`n📊 Deployment Status:" -ForegroundColor Green
kubectl get all

# Step 10: Setup Ingress (if needed)
Write-Host "`n🌐 Setting up Ingress..." -ForegroundColor Yellow
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --set controller.service.type=LoadBalancer

# Step 11: Get external IP
Write-Host "`n🌍 Getting external access information..." -ForegroundColor Green
Write-Host "External IPs:" -ForegroundColor Yellow
kubectl get services --all-namespaces -o wide | Where-Object { $_ -match "LoadBalancer" }

Write-Host "`n🎉 Deployment completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Wait for external IP to be assigned (may take 2-3 minutes)" -ForegroundColor White
Write-Host "2. Access your app at the LoadBalancer IP" -ForegroundColor White
Write-Host "3. Monitor with: kubectl get all" -ForegroundColor White
Write-Host "4. Check logs with: kubectl logs -f deployment/api-gateway" -ForegroundColor White
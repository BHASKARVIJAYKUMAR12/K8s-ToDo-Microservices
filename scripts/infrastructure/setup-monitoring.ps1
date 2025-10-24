# Production Monitoring Stack Setup
# This script deploys Prometheus, Grafana, and Jaeger for comprehensive observability

param(
    [Parameter(Mandatory=$true)]
    [string]$PROJECT_ID,
    
    [Parameter(Mandatory=$false)]
    [string]$CLUSTER_NAME = "todo-app-cluster",
    
    [Parameter(Mandatory=$false)]
    [string]$REGION = "us-central1",
    
    [Parameter(Mandatory=$false)]
    [string]$GRAFANA_PASSWORD = (New-Guid).ToString().Substring(0,16)
)

Write-Host "📊 Setting up production monitoring stack..." -ForegroundColor Green
Write-Host "Project ID: $PROJECT_ID" -ForegroundColor Yellow
Write-Host "Grafana Password: $GRAFANA_PASSWORD" -ForegroundColor Yellow

# Connect to cluster
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID

# Add Helm repositories
Write-Host "`n📦 Adding monitoring Helm repositories..." -ForegroundColor Blue
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# Create monitoring namespace
Write-Host "`n🏗️ Creating monitoring namespace..." -ForegroundColor Blue
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack (Prometheus + Grafana + AlertManager)
Write-Host "`n📈 Installing Prometheus and Grafana stack..." -ForegroundColor Blue
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --set prometheus.prometheusSpec.retention=30d `
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=standard-rwo `
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi `
  --set grafana.adminPassword=$GRAFANA_PASSWORD `
  --set grafana.persistence.enabled=true `
  --set grafana.persistence.storageClassName=standard-rwo `
  --set grafana.persistence.size=10Gi `
  --set grafana.service.type=ClusterIP `
  --set grafana.ingress.enabled=false `
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName=standard-rwo `
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=10Gi

# Install Jaeger for distributed tracing
Write-Host "`n🔍 Installing Jaeger for distributed tracing..." -ForegroundColor Blue
helm upgrade --install jaeger jaegertracing/jaeger `
  --namespace monitoring `
  --set provisionDataStore.cassandra=false `
  --set provisionDataStore.elasticsearch=true `
  --set storage.type=elasticsearch `
  --set elasticsearch.cluster.name=jaeger-elasticsearch `
  --set elasticsearch.volumeClaimTemplate.storageClassName=standard-rwo `
  --set elasticsearch.volumeClaimTemplate.resources.requests.storage=20Gi

# Wait for deployments to be ready
Write-Host "`n⏳ Waiting for monitoring stack to be ready..." -ForegroundColor Yellow
kubectl wait --namespace monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=prometheus --timeout=300s
kubectl wait --namespace monitoring --for=condition=ready pod --selector=app.kubernetes.io/name=grafana --timeout=300s

Write-Host "`n🎉 Monitoring stack installation completed!" -ForegroundColor Green
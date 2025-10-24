# Production Secrets Setup for GKE Deployment
# This script creates secure secrets using Google Secret Manager

param(
    [Parameter(Mandatory=$true)]
    [string]$PROJECT_ID,
    
    [Parameter(Mandatory=$false)]
    [string]$CLUSTER_NAME = "todo-app-cluster",
    
    [Parameter(Mandatory=$false)]
    [string]$REGION = "us-central1"
)

Write-Host "🔐 Setting up production secrets for GKE deployment..." -ForegroundColor Green
Write-Host "Project ID: $PROJECT_ID" -ForegroundColor Yellow
Write-Host "Cluster: $CLUSTER_NAME" -ForegroundColor Yellow
Write-Host "Region: $REGION" -ForegroundColor Yellow

# Check if required tools are installed
Write-Host "`n🔍 Checking prerequisites..." -ForegroundColor Blue
$tools = @("gcloud", "kubectl")
foreach ($tool in $tools) {
    if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Error "$tool is not installed or not in PATH!"
        exit 1
    }
    Write-Host "✅ $tool is available" -ForegroundColor Green
}

# Set project and get credentials
Write-Host "`n🏗️ Setting up GCP project..." -ForegroundColor Blue
gcloud config set project $PROJECT_ID
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

# Enable required APIs
Write-Host "`n⚙️ Enabling required GCP APIs..." -ForegroundColor Blue
$apis = @(
    "secretmanager.googleapis.com",
    "container.googleapis.com",
    "cloudsql.googleapis.com"
)

foreach ($api in $apis) {
    Write-Host "Enabling $api..." -ForegroundColor Yellow
    gcloud services enable $api
}

# Generate secure random secrets
Write-Host "`n🔑 Generating secure secrets..." -ForegroundColor Blue
function Generate-SecureSecret {
    param([int]$Length = 32)
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    $secret = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $secret += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $secret
}

# Create secrets in Google Secret Manager
$secrets = @{
    "db-password" = Generate-SecureSecret -Length 32
    "jwt-secret" = Generate-SecureSecret -Length 64
    "redis-password" = Generate-SecureSecret -Length 24
    "session-secret" = Generate-SecureSecret -Length 48
}

Write-Host "`n🏪 Creating secrets in Google Secret Manager..." -ForegroundColor Blue
foreach ($secretName in $secrets.Keys) {
    $secretValue = $secrets[$secretName]
    
    # Check if secret already exists
    $existingSecret = gcloud secrets describe $secretName --project=$PROJECT_ID 2>$null
    if ($existingSecret) {
        Write-Host "⚠️ Secret $secretName already exists, creating new version..." -ForegroundColor Yellow
        echo $secretValue | gcloud secrets versions add $secretName --data-file=-
    } else {
        Write-Host "➕ Creating new secret: $secretName" -ForegroundColor Green
        echo $secretValue | gcloud secrets create $secretName --data-file=-
    }
    
    # Grant access to GKE service account
    $serviceAccount = "$PROJECT_ID.svc.id.goog[default/default]"
    gcloud secrets add-iam-policy-binding $secretName --member="serviceAccount:$serviceAccount" --role="roles/secretmanager.secretAccessor"
}

# Create Kubernetes Secret manifest using Google Secret Manager
Write-Host "`n📄 Creating Kubernetes Secret manifest..." -ForegroundColor Blue
$secretManifest = @"
# Production Secrets using Google Secret Manager
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: default
  annotations:
    secret-manager.gcp/project-id: "$PROJECT_ID"
type: Opaque
stringData:
  # These will be automatically populated by Secret Manager CSI driver
  DB_HOST: "postgres-service"
  DB_PORT: "5432"
  DB_NAME: "todoapp"
  DB_USER: "postgres"
  REDIS_HOST: "redis-service"
  REDIS_PORT: "6379"
  NODE_ENV: "production"
---
# External Secrets Operator configuration
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: gcpsm-secret-store
  namespace: default
spec:
  provider:
    gcpsm:
      projectId: "$PROJECT_ID"
      auth:
        workloadIdentity:
          clusterLocation: "$REGION"
          clusterName: "$CLUSTER_NAME"
          serviceAccountRef:
            name: external-secrets-sa
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-external-secrets
  namespace: default
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: gcpsm-secret-store
    kind: SecretStore
  target:
    name: app-secrets
    creationPolicy: Owner
  data:
  - secretKey: DB_PASSWORD
    remoteRef:
      key: db-password
  - secretKey: JWT_SECRET
    remoteRef:
      key: jwt-secret
  - secretKey: REDIS_PASSWORD
    remoteRef:
      key: redis-password
  - secretKey: SESSION_SECRET
    remoteRef:
      key: session-secret
"@

$secretManifest | Out-File -FilePath "k8s-specifications\production-secrets.yaml" -Encoding UTF8

# Create External Secrets Operator service account
Write-Host "`n👤 Setting up External Secrets Operator..." -ForegroundColor Blue
$serviceAccountManifest = @"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-sa
  namespace: default
  annotations:
    iam.gke.io/gcp-service-account: "external-secrets@$PROJECT_ID.iam.gserviceaccount.com"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-secrets-role
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create", "update", "get", "list", "watch"]
- apiGroups: ["external-secrets.io"]
  resources: ["externalsecrets", "secretstores"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-secrets-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-secrets-role
subjects:
- kind: ServiceAccount
  name: external-secrets-sa
  namespace: default
"@

$serviceAccountManifest | Out-File -FilePath "k8s-specifications\external-secrets-sa.yaml" -Encoding UTF8

# Create Google Cloud IAM Service Account for External Secrets
Write-Host "`n🔧 Creating Google Cloud Service Account..." -ForegroundColor Blue
$gsaName = "external-secrets"
$gsaEmail = "$gsaName@$PROJECT_ID.iam.gserviceaccount.com"

# Check if service account exists
$existingGsa = gcloud iam service-accounts describe $gsaEmail --project=$PROJECT_ID 2>$null
if (-not $existingGsa) {
    Write-Host "Creating Google Cloud Service Account: $gsaEmail" -ForegroundColor Green
    gcloud iam service-accounts create $gsaName --display-name="External Secrets Operator"
}

# Grant Secret Manager access
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$gsaEmail" --role="roles/secretmanager.secretAccessor"

# Enable Workload Identity binding
$kubernetesServiceAccount = "default/external-secrets-sa"
gcloud iam service-accounts add-iam-policy-binding $gsaEmail --role="roles/iam.workloadIdentityUser" --member="serviceAccount:$PROJECT_ID.svc.id.goog[$kubernetesServiceAccount]"

Write-Host "`n🎉 Secrets setup completed successfully!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Install External Secrets Operator: helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace" -ForegroundColor White
Write-Host "2. Apply the secret manifests: kubectl apply -f k8s-specifications/production-secrets.yaml" -ForegroundColor White
Write-Host "3. Apply the service account: kubectl apply -f k8s-specifications/external-secrets-sa.yaml" -ForegroundColor White
Write-Host "4. Verify secrets are created: kubectl get secrets" -ForegroundColor White

Write-Host "`n🔐 Secret Management Summary:" -ForegroundColor Cyan
Write-Host "✅ Google Secret Manager secrets created" -ForegroundColor Green
Write-Host "✅ External Secrets Operator configuration ready" -ForegroundColor Green
Write-Host "✅ Workload Identity configured" -ForegroundColor Green
Write-Host "✅ RBAC permissions set up" -ForegroundColor Green
Write-Host "`n🚨 Important: Store these secret keys securely for backup purposes!" -ForegroundColor Red
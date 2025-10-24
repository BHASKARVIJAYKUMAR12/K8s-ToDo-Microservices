# Local Kubernetes Deployment Script
# This script deploys the Todo Application to local Docker Desktop Kubernetes

param(
    [Parameter(Mandatory=$false)]
    [switch]$CleanDeploy = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableMonitoring = $false
)

Write-Host "Deploying Todo Application to Local Kubernetes..." -ForegroundColor Green

# Verify we're using local Kubernetes context
$currentContext = kubectl config current-context
if ($currentContext -ne "docker-desktop") {
    Write-Host "Current kubectl context is '$currentContext'" -ForegroundColor Yellow
    Write-Host "Switching to docker-desktop context..." -ForegroundColor Yellow
    kubectl config use-context docker-desktop
}

Write-Host "Using Kubernetes context: $(kubectl config current-context)" -ForegroundColor Green

# Clean up existing deployment if requested
if ($CleanDeploy) {
    Write-Host "`nCleaning up existing deployment..." -ForegroundColor Yellow
    kubectl delete namespace todo-app --ignore-not-found=true
    kubectl delete pv --all --ignore-not-found=true
    kubectl delete pvc --all --ignore-not-found=true
    Start-Sleep -Seconds 10
}

# Build images if not skipped
if (-not $SkipBuild) {
    Write-Host "`nBuilding Docker images..." -ForegroundColor Blue
    & ".\scripts\development\local-build.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed! Stopping deployment." -ForegroundColor Red
        exit 1
    }
}

# Create namespace
Write-Host "`nCreating namespace..." -ForegroundColor Blue
kubectl create namespace todo-app --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=todo-app

# Create local secrets (simplified for local testing)
Write-Host "`nCreating local secrets..." -ForegroundColor Blue
@'
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: todo-app
type: Opaque
stringData:
  DB_HOST: "postgres-service"
  DB_PORT: "5432"
  DB_NAME: "todoapp"
  DB_USER: "postgres"
  DB_PASSWORD: "password"
  JWT_SECRET: "local-development-jwt-secret-key"
  REDIS_HOST: "redis-service"
  REDIS_PORT: "6379"
  REDIS_PASSWORD: ""
  SESSION_SECRET: "local-development-session-secret"
  NODE_ENV: "development"
'@ | kubectl apply -f -

# Create local ConfigMap
Write-Host "`nCreating local configuration..." -ForegroundColor Blue
@'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: todo-app
data:
  NODE_ENV: "development"
  LOG_LEVEL: "debug"
  TODO_SERVICE_URL: "http://todo-service:3001"
  USER_SERVICE_URL: "http://user-service:3002"
  NOTIFICATION_SERVICE_URL: "http://notification-service:3003"
  FRONTEND_URL: "http://frontend-service"
'@ | kubectl apply -f -

# Deploy PostgreSQL
Write-Host "`nDeploying PostgreSQL..." -ForegroundColor Blue
@'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASSWORD
        - name: POSTGRES_DB
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_NAME
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: todo-app
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
'@ | kubectl apply -f -

# Deploy Redis
Write-Host "`nDeploying Redis..." -ForegroundColor Blue
@'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: todo-app
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
'@ | kubectl apply -f -

# Wait for databases to be ready
Write-Host "`nWaiting for databases to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=120s deployment/postgres -n todo-app
kubectl wait --for=condition=available --timeout=120s deployment/redis -n todo-app

# Deploy User Service
Write-Host "`nDeploying User Service..." -ForegroundColor Blue
@'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: todo-app/user-service:local
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3002
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
        livenessProbe:
          httpGet:
            path: /health
            port: 3002
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3002
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: todo-app
spec:
  selector:
    app: user-service
  ports:
  - port: 3002
    targetPort: 3002
'@ | kubectl apply -f -

# Deploy Todo Service
Write-Host "`nDeploying Todo Service..." -ForegroundColor Blue
@'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-service
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: todo-service
  template:
    metadata:
      labels:
        app: todo-service
    spec:
      containers:
      - name: todo-service
        image: todo-app/todo-service:local
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3001
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: todo-service
  namespace: todo-app
spec:
  selector:
    app: todo-service
  ports:
  - port: 3001
    targetPort: 3001
'@ | kubectl apply -f -

# Deploy Notification Service
Write-Host "`nDeploying Notification Service..." -ForegroundColor Blue
@'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notification-service
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: notification-service
  template:
    metadata:
      labels:
        app: notification-service
    spec:
      containers:
      - name: notification-service
        image: todo-app/notification-service:local
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3003
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
        livenessProbe:
          httpGet:
            path: /health
            port: 3003
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3003
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: notification-service
  namespace: todo-app
spec:
  selector:
    app: notification-service
  ports:
  - port: 3003
    targetPort: 3003
'@ | kubectl apply -f -

# Deploy API Gateway
Write-Host "`nDeploying API Gateway..." -ForegroundColor Blue
@'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: api-gateway
        image: todo-app/api-gateway:local
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: app-secrets
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway-service
  namespace: todo-app
spec:
  selector:
    app: api-gateway
  ports:
  - port: 8080
    targetPort: 8080
  type: LoadBalancer
'@ | kubectl apply -f -

# Deploy Frontend
Write-Host "`nDeploying Frontend..." -ForegroundColor Blue
@'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: todo-app/frontend:local
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: todo-app
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
'@ | kubectl apply -f -

# Wait for all deployments to be ready
Write-Host "`nWaiting for all services to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment --all -n todo-app

# Get service information
Write-Host "`n===== Deployment Status =====" -ForegroundColor Cyan
kubectl get pods,services -n todo-app

# Get access URLs
Write-Host "`n===== Access Information =====" -ForegroundColor Cyan
$frontendPort = kubectl get service frontend-service -n todo-app -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
$apiPort = kubectl get service api-gateway-service -n todo-app -o jsonpath='{.spec.ports[0].nodePort}' 2>$null

if ($frontendPort) {
    Write-Host "Frontend: http://localhost:$frontendPort" -ForegroundColor Green
} else {
    Write-Host "Frontend: http://localhost (port-forward required)" -ForegroundColor Yellow
}

if ($apiPort) {
    Write-Host "API Gateway: http://localhost:$apiPort" -ForegroundColor Green
} else {
    Write-Host "API Gateway: http://localhost:8080 (port-forward required)" -ForegroundColor Yellow
}

Write-Host "`n===== Port Forwarding Commands (if needed) =====" -ForegroundColor Cyan
Write-Host "kubectl port-forward -n todo-app svc/frontend-service 3000:80" -ForegroundColor White
Write-Host "kubectl port-forward -n todo-app svc/api-gateway-service 8080:8080" -ForegroundColor White

Write-Host "`n===== Testing Commands =====" -ForegroundColor Cyan
Write-Host ".\scripts\development\test-local-deployment.ps1" -ForegroundColor White

Write-Host "`nLocal Kubernetes deployment completed!" -ForegroundColor Green

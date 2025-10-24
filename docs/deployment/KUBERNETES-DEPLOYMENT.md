# 🚀 Todo Microservices - Kubernetes Deployment Guide

## 📋 Overview

Complete deployment guide for Todo Microservices application on Kubernetes (Docker Desktop and GKE).

**Local Working Configuration:**

- Frontend: `localhost:3000` → Nginx on port 80
- API Gateway: `localhost:8080` → Proxies to backend services
- User Service: `localhost:3002` → Authentication
- Todo Service: `localhost:3001` → Todo CRUD operations
- Notification Service: `localhost:3003` → Notifications
- PostgreSQL: `localhost:5432` → Database
- Redis: `localhost:6379` → Cache

**This same configuration works in Kubernetes!**

---

## 🎯 Quick Start

### Option 1: Automated Deployment (Recommended)

**Windows (PowerShell):**

```powershell
.\scripts\build-and-deploy.ps1
```

**Linux/Mac (Bash):**

```bash
chmod +x scripts/build-and-deploy.sh
./scripts/build-and-deploy.sh
```

### Option 2: Manual Step-by-Step

See detailed instructions below.

---

## 📦 Prerequisites

### Required Software

1. **Docker Desktop** with Kubernetes enabled

   - Download: https://www.docker.com/products/docker-desktop
   - Enable Kubernetes in Settings → Kubernetes → Enable Kubernetes

2. **kubectl** (usually comes with Docker Desktop)

   ```bash
   kubectl version --client
   ```

3. **Git** (for cloning the repository)

### Verify Prerequisites

```powershell
# Check Docker
docker version

# Check kubectl
kubectl version --client

# Check Kubernetes cluster
kubectl cluster-info

# Should show: Kubernetes control plane is running at...
```

---

## 🔨 Build Docker Images

### Step 1: Clean Old Images

```powershell
# Remove old images
docker images | Select-String "todo-|api-gateway|frontend" | ForEach-Object {
    $parts = ($_ -replace '\s+', ' ') -split ' '
    docker rmi -f $parts[2]
}

# Clean up dangling images
docker image prune -f
```

### Step 2: Build All Services

```powershell
# Build frontend
cd frontend
docker build -t frontend:latest --build-arg REACT_APP_API_URL="/api" .
cd ..

# Build API Gateway
cd api-gateway
docker build -t api-gateway:latest .
cd ..

# Build User Service
cd user-service
docker build -t user-service:latest .
cd ..

# Build Todo Service
cd todo-service
docker build -t todo-service:latest .
cd ..

# Build Notification Service
cd notification-service
docker build -t notification-service:latest .
cd ..
```

### Step 3: Verify Images

```powershell
docker images | Select-String "frontend|api-gateway|user-service|todo-service|notification-service"
```

You should see all 5 images with `latest` tag.

---

## ☸️ Deploy to Kubernetes

### Step 1: Create Namespace

```powershell
kubectl create namespace todo-app
```

### Step 2: Deploy Infrastructure (Databases)

```powershell
# Deploy PostgreSQL
kubectl apply -f k8s/simple/postgres-deployment.yaml

# Deploy Redis
kubectl apply -f k8s/simple/redis-deployment.yaml

# Wait for databases to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n todo-app --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n todo-app --timeout=120s
```

### Step 3: Deploy Backend Services

```powershell
# Deploy User Service
kubectl apply -f k8s/simple/user-service-deployment.yaml

# Deploy Todo Service
kubectl apply -f k8s/simple/todo-service-deployment.yaml

# Deploy Notification Service
kubectl apply -f k8s/simple/notification-service-deployment.yaml

# Wait a bit for services to start
Start-Sleep -Seconds 15
```

### Step 4: Deploy API Gateway

```powershell
kubectl apply -f k8s/simple/api-gateway-deployment.yaml

# Wait for API Gateway
Start-Sleep -Seconds 10
```

### Step 5: Deploy Frontend

```powershell
kubectl apply -f k8s/simple/frontend-deployment.yaml
```

### Step 6: Verify Deployment

```powershell
# Check all pods
kubectl get pods -n todo-app

# Check all services
kubectl get services -n todo-app

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n todo-app --timeout=300s
```

**Expected Output:**

```
NAME                                    READY   STATUS    RESTARTS   AGE
api-gateway-xxxxxxxxxx-xxxxx            1/1     Running   0          2m
frontend-xxxxxxxxxx-xxxxx               1/1     Running   0          1m
notification-service-xxxxxxxxxx-xxxxx   1/1     Running   0          3m
postgres-xxxxxxxxxx-xxxxx               1/1     Running   0          5m
redis-xxxxxxxxxx-xxxxx                  1/1     Running   0          5m
todo-service-xxxxxxxxxx-xxxxx           1/1     Running   0          3m
user-service-xxxxxxxxxx-xxxxx           1/1     Running   0          3m
```

---

## 🌐 Access the Application

### Method 1: Port Forwarding (Recommended for Testing)

**Terminal 1 - Frontend:**

```powershell
kubectl port-forward svc/frontend-service 3000:80 -n todo-app
```

**Terminal 2 - API Gateway:**

```powershell
kubectl port-forward svc/api-gateway-service 8080:8080 -n todo-app
```

Then open: **http://localhost:3000**

### Method 2: LoadBalancer (Docker Desktop)

Docker Desktop automatically assigns LoadBalancer IPs:

```powershell
# Get the external IP
kubectl get services -n todo-app

# Look for frontend-service EXTERNAL-IP (usually localhost or 127.0.0.1)
```

Access via the LoadBalancer IP on port 80.

### Method 3: Ingress (Advanced)

If you have ingress-nginx installed:

```powershell
# Deploy ingress
kubectl apply -f k8s/simple/ingress.yaml

# Get ingress IP
kubectl get ingress -n todo-app
```

---

## 🧪 Testing the Application

### 1. Health Checks

```powershell
# Check API Gateway
kubectl exec -n todo-app deployment/api-gateway -- curl -s http://localhost:8080/health

# Check User Service
kubectl exec -n todo-app deployment/user-service -- curl -s http://localhost:3002/health

# Check Todo Service
kubectl exec -n todo-app deployment/todo-service -- curl -s http://localhost:3001/health
```

### 2. Test Registration

1. Open http://localhost:3000 (with port-forward)
2. Click "Register"
3. Fill in details:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `password123`
4. Submit

**Expected:** Should register successfully and redirect to todos page.

### 3. Test Todos

1. After logging in, create a todo
2. Todo should persist
3. Can mark as complete/delete

### 4. Check Logs

```powershell
# API Gateway logs
kubectl logs -f deployment/api-gateway -n todo-app

# User Service logs
kubectl logs -f deployment/user-service -n todo-app

# Todo Service logs
kubectl logs -f deployment/todo-service -n todo-app
```

Look for:

- ✅ No CORS errors
- ✅ Successful proxy requests
- ✅ Database connections established
- ✅ 200/201 status codes

---

## 🔍 Troubleshooting

### Pods Not Starting

```powershell
# Check pod status
kubectl get pods -n todo-app

# Describe problem pod
kubectl describe pod <pod-name> -n todo-app

# Check logs
kubectl logs <pod-name> -n todo-app
```

**Common Issues:**

- **ImagePullBackOff**: Image not built or tagged correctly
- **CrashLoopBackOff**: Application error, check logs
- **Pending**: Resource constraints or PVC issues

### Database Connection Errors

```powershell
# Check if postgres is running
kubectl get pods -l app=postgres -n todo-app

# Check postgres logs
kubectl logs -l app=postgres -n todo-app

# Test connection from user-service
kubectl exec -n todo-app deployment/user-service -- nc -zv postgres-service 5432
```

### CORS Errors

1. **Check API Gateway environment:**

   ```powershell
   kubectl get configmap api-gateway-config -n todo-app -o yaml
   ```

   Should have: `ALLOWED_ORIGINS: "http://frontend-service,http://frontend-service:80"`

2. **Check logs for CORS rejections:**

   ```powershell
   kubectl logs -f deployment/api-gateway -n todo-app | Select-String "CORS"
   ```

3. **Verify frontend is using correct API URL:**
   Frontend should call `/api/*` which ingress routes to API Gateway

### Service Not Accessible

```powershell
# Check service endpoints
kubectl get endpoints -n todo-app

# Test internal connectivity
kubectl run test-pod --image=curlimages/curl -it --rm -n todo-app -- sh

# Inside the pod:
curl http://api-gateway-service:8080/health
curl http://user-service:3002/health
curl http://todo-service:3001/health
```

---

## 🗑️ Cleanup

### Remove Everything

```powershell
# Delete namespace (removes all resources)
kubectl delete namespace todo-app
```

### Remove Docker Images

```powershell
docker rmi frontend:latest api-gateway:latest user-service:latest todo-service:latest notification-service:latest
```

---

## 🚀 Deploy to GKE (Google Kubernetes Engine)

### Prerequisites

1. **Google Cloud Account** with billing enabled
2. **gcloud CLI** installed
3. **GKE cluster** created

### Step 1: Setup GCP Project

```bash
# Set project ID
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### Step 2: Create GKE Cluster

```bash
# Create cluster
gcloud container clusters create todo-cluster \
    --zone us-central1-a \
    --num-nodes 3 \
    --machine-type n1-standard-2 \
    --enable-autoscaling \
    --min-nodes 2 \
    --max-nodes 5

# Get credentials
gcloud container clusters get-credentials todo-cluster --zone us-central1-a
```

### Step 3: Build and Push Images to GCR

```bash
# Build and tag for GCR
docker build -t gcr.io/$PROJECT_ID/frontend:latest ./frontend
docker build -t gcr.io/$PROJECT_ID/api-gateway:latest ./api-gateway
docker build -t gcr.io/$PROJECT_ID/user-service:latest ./user-service
docker build -t gcr.io/$PROJECT_ID/todo-service:latest ./todo-service
docker build -t gcr.io/$PROJECT_ID/notification-service:latest ./notification-service

# Configure Docker for GCR
gcloud auth configure-docker gcr.io

# Push images
docker push gcr.io/$PROJECT_ID/frontend:latest
docker push gcr.io/$PROJECT_ID/api-gateway:latest
docker push gcr.io/$PROJECT_ID/user-service:latest
docker push gcr.io/$PROJECT_ID/todo-service:latest
docker push gcr.io/$PROJECT_ID/notification-service:latest
```

### Step 4: Update Kubernetes Manifests for GKE

1. Change `imagePullPolicy: Never` to `imagePullPolicy: Always`
2. Update image names to `gcr.io/$PROJECT_ID/service:latest`
3. Change frontend service type to `LoadBalancer` or use Ingress
4. Update secrets for production (generate strong JWT secret)

### Step 5: Deploy to GKE

```bash
# Use the automated script
chmod +x scripts/build-and-deploy.sh
ENVIRONMENT=gke GCP_PROJECT_ID=$PROJECT_ID ./scripts/build-and-deploy.sh
```

### Step 6: Get External IP

```bash
# Get LoadBalancer IP
kubectl get services -n todo-app

# Or get Ingress IP
kubectl get ingress -n todo-app
```

Access your application via the external IP!

---

## 📊 Monitoring

### View All Resources

```powershell
kubectl get all -n todo-app
```

### Watch Pod Status

```powershell
kubectl get pods -n todo-app -w
```

### Resource Usage

```powershell
kubectl top pods -n todo-app
kubectl top nodes
```

### Events

```powershell
kubectl get events -n todo-app --sort-by='.lastTimestamp'
```

---

## 📝 Configuration Files

### Kubernetes Manifests Structure

```
k8s/
├── simple/                          # Simplified manifests for testing
│   ├── namespace.yaml              # Namespace definition
│   ├── postgres-deployment.yaml    # PostgreSQL database
│   ├── redis-deployment.yaml       # Redis cache
│   ├── user-service-deployment.yaml
│   ├── todo-service-deployment.yaml
│   ├── notification-service-deployment.yaml
│   ├── api-gateway-deployment.yaml
│   ├── frontend-deployment.yaml
│   └── ingress.yaml                # Optional ingress
└── (future: production manifests with advanced features)
```

### Environment Variables

All environment variables are defined in ConfigMaps and Secrets:

**ConfigMaps:**

- Service URLs for inter-service communication
- Node environment (production/development)
- Database connection details
- Port numbers

**Secrets:**

- JWT_SECRET (must be same across all services)
- DB_PASSWORD
- POSTGRES_PASSWORD

---

## ✅ Success Criteria

Your deployment is successful when:

1. ✅ All pods show `Running` status
2. ✅ All pods pass health checks (1/1 Ready)
3. ✅ Can access frontend via port-forward
4. ✅ Can register new user
5. ✅ Can create todos
6. ✅ No CORS errors in browser console
7. ✅ API Gateway logs show 200/201 status codes
8. ✅ Todos persist after page refresh

---

## 🆘 Need Help?

1. **Check pod logs:** `kubectl logs <pod-name> -n todo-app`
2. **Describe pod:** `kubectl describe pod <pod-name> -n todo-app`
3. **Check events:** `kubectl get events -n todo-app`
4. **Review documentation** in `docs/` folder
5. **Check troubleshooting guides** in `docs/troubleshooting/`

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)

---

**Last Updated:** October 21, 2025  
**Version:** 2.0 - Kubernetes Deployment Ready

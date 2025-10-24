# 🔍 How to View Your Kubernetes Deployment

## ✅ **Your Deployment is Running!**

All your pods are successfully running in the `todo-app` namespace. Here's how to visualize and monitor them:

---

## 📊 **Method 1: Command Line (Fastest)**

### View All Resources

```powershell
# See everything at once
kubectl get all -n todo-app

# Detailed pod information
kubectl get pods -n todo-app -o wide

# Watch pods in real-time
kubectl get pods -n todo-app --watch

# View services
kubectl get services -n todo-app

# View deployments
kubectl get deployments -n todo-app
```

### Current Status

Your deployment has **7 pods running**:

| Pod                  | Status     | IP          | Age  |
| -------------------- | ---------- | ----------- | ---- |
| api-gateway          | ✅ Running | 10.244.1.14 | ~10m |
| frontend             | ✅ Running | 10.244.1.15 | ~10m |
| notification-service | ✅ Running | 10.244.1.13 | ~10m |
| postgres             | ✅ Running | 10.244.1.9  | ~10m |
| redis                | ✅ Running | 10.244.1.10 | ~10m |
| todo-service         | ✅ Running | 10.244.1.12 | ~10m |
| user-service         | ✅ Running | 10.244.1.11 | ~10m |

---

## 🌐 **Method 2: Kubernetes Dashboard (Visual UI)**

### Step 1: Start Dashboard Proxy

```powershell
# Start the proxy (keep this terminal open)
kubectl proxy
```

### Step 2: Access Dashboard

Open your browser and go to:

```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### Step 3: Login with Token

**Your Access Token (valid for 24 hours):**

```
eyJhbGciOiJSUzI1NiIsImtpZCI6IkVRdm11cV85TjF1WkJxZks4OEdiZFJhUkp4MEpNM0wySFZiLWFHZTlRMUkifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzYwNzc5OTIxLCJpYXQiOjE3NjA2OTM1MjEsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiNDE1NGRiOTctOGY0Zi00OTU5LWE5ZDAtZjEzMDM2ZDhlMmI1Iiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJkYXNoYm9hcmQtYWRtaW4iLCJ1aWQiOiI3ZGYzOWJhYS02OGNmLTQ3M2MtOTZiZC1kNWMzZTY3YTlmMzcifX0sIm5iZiI6MTc2MDY5MzUyMSwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmVybmV0ZXMtZGFzaGJvYXJkOmRhc2hib2FyZC1hZG1pbiJ9.jDV0gkdq3Ca3k54hyTzD7hFKfD1N3E5y5bOH9DMygTzeDWpZf5vBQPBOKLrKoql2NbhQAndZryAa-c7vFITvj1oeXkhjuALF6tKmieinlc-mPyayei9sZD-bvdGosZV4kYvxnuIUwllS1ja4hXyiAVxMYeIsA1aSFeFDHFO1ItrSZ4RKgtFgEvMPD6YyoPELD85evB1wzM3vO44yzdPqyTyxIhzUDhbFqLfeMGCzbUNl29KK1LUKWVXsd_Je34WhzTVJTA6fQqrKUCwne1rikznC5z1W9v_ZPq3QVCZBkkiiCyfTgeqvDH5EMwrm1a6b6mYA_N9CZC8vX5hjoYY_tg
```

**Steps:**

1. Copy the token above
2. Click "Token" on the login page
3. Paste the token
4. Click "Sign in"
5. In the left sidebar, select namespace: **todo-app**
6. Navigate to **Workloads > Pods** to see your pods

### Generate New Token (if expired)

```powershell
kubectl create token dashboard-admin -n kubernetes-dashboard --duration=24h
```

---

## 🖥️ **Method 3: Lens Desktop (Best Visual Tool)**

### Install Lens (Free Kubernetes IDE)

1. Download from: https://k8slens.dev/
2. Install and launch Lens
3. It will auto-detect your Docker Desktop cluster
4. Click on your cluster
5. Navigate to **Namespaces > todo-app**
6. View **Pods**, **Services**, **Deployments**, etc.

**Benefits:**

- ✅ Beautiful, modern UI
- ✅ Real-time monitoring
- ✅ Built-in terminal
- ✅ Log viewing
- ✅ Resource metrics
- ✅ Port forwarding management

---

## 🔧 **Method 4: K9s (Terminal UI)**

### Install K9s

```powershell
# Install via Chocolatey
choco install k9s

# Or via Scoop
scoop install k9s
```

### Launch K9s

```powershell
# Start K9s
k9s

# Navigate to todo-app namespace
# Press '0' to show all namespaces
# Use arrow keys to select 'todo-app'
# Press Enter
```

**Keyboard Shortcuts:**

- `:pods` - View pods
- `:svc` - View services
- `:deploy` - View deployments
- `l` - View logs
- `d` - Describe resource
- `Ctrl+C` - Exit

---

## 📱 **Method 5: Docker Desktop (Limited)**

### Why you don't see pods in Docker Desktop

Docker Desktop's Kubernetes UI is **very basic** and doesn't show namespace-specific resources well. Here's what you can do:

1. Open **Docker Desktop**
2. Click **Settings** (gear icon)
3. Go to **Kubernetes** tab
4. Make sure "Enable Kubernetes" is ✅ checked
5. The UI shows minimal info - **use other methods instead**

**Note:** Docker Desktop shows containers, but Kubernetes pods are abstracted. Use the command line or dashboard for better visibility.

---

## 🔍 **Quick Commands Cheat Sheet**

```powershell
# View pods
kubectl get pods -n todo-app

# View pod logs
kubectl logs -f deployment/api-gateway -n todo-app

# Describe a pod (troubleshooting)
kubectl describe pod POD-NAME -n todo-app

# Execute command in pod
kubectl exec -it POD-NAME -n todo-app -- sh

# Port forward to service
kubectl port-forward -n todo-app svc/frontend-service 3000:80

# View resource usage
kubectl top pods -n todo-app

# View events
kubectl get events -n todo-app --sort-by=.metadata.creationTimestamp

# View all resources
kubectl get all -n todo-app

# Delete namespace (cleanup)
kubectl delete namespace todo-app
```

---

## 📊 **Monitoring Your Application**

### Check Application Health

```powershell
# API Gateway health
curl.exe http://localhost:8080/health

# View all service endpoints
kubectl get endpoints -n todo-app

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it -n todo-app -- sh
# Inside pod: wget -O- http://api-gateway-service:8080/health
```

### View Logs from All Services

```powershell
# API Gateway
kubectl logs -f deployment/api-gateway -n todo-app

# User Service
kubectl logs -f deployment/user-service -n todo-app

# Todo Service
kubectl logs -f deployment/todo-service -n todo-app

# All logs (last 50 lines)
kubectl logs -l app=api-gateway -n todo-app --tail=50
```

---

## 🎯 **Recommended Workflow**

### For Quick Checks

```powershell
kubectl get pods -n todo-app
```

### For Detailed Monitoring

1. **Install Lens** (best option for beginners)
2. Or use **Kubernetes Dashboard** (web-based)

### For Power Users

- Use **K9s** for terminal UI
- Or stick with **kubectl** commands

---

## 🚀 **Quick Access Script**

Create a PowerShell script for quick access:

```powershell
# Save as: quick-k8s-status.ps1

Write-Host "`n=== Todo App Kubernetes Status ===" -ForegroundColor Cyan

Write-Host "`n🔹 Pods:" -ForegroundColor Green
kubectl get pods -n todo-app

Write-Host "`n🔹 Services:" -ForegroundColor Green
kubectl get services -n todo-app

Write-Host "`n🔹 Application URLs:" -ForegroundColor Green
Write-Host "Frontend: http://localhost:3000 (with port-forward)" -ForegroundColor Yellow
Write-Host "API: http://localhost:8080 (with port-forward)" -ForegroundColor Yellow

Write-Host "`n🔹 Quick Commands:" -ForegroundColor Green
Write-Host "kubectl logs -f deployment/api-gateway -n todo-app" -ForegroundColor White
Write-Host "kubectl port-forward -n todo-app svc/frontend-service 3000:80" -ForegroundColor White
Write-Host "kubectl port-forward -n todo-app svc/api-gateway-service 8080:8080" -ForegroundColor White
```

Run it:

```powershell
.\quick-k8s-status.ps1
```

---

## ✅ **Your Deployment is Confirmed Working!**

Based on the output:

- ✅ All 7 pods are **Running**
- ✅ All deployments are **Available**
- ✅ Services are **Configured**
- ✅ API Gateway responds to health checks
- ✅ Frontend is accessible

**You can now:**

1. Access frontend at http://localhost:3000
2. Access API at http://localhost:8080
3. Use Kubernetes Dashboard for visual monitoring
4. Deploy to GKE when ready

---

**💡 Tip:** Docker Desktop's Kubernetes UI is intentionally minimal. For production-grade monitoring, always use kubectl, Kubernetes Dashboard, Lens, or K9s.

# 🧪 Local Kubernetes Testing with Docker Desktop

> **Complete guide for testing your K8s-ToDo-Microservices application locally using Docker Desktop Kubernetes before deploying to GKE**

## 📋 **Overview**

This guide will help you:

- ✅ Set up Docker Desktop Kubernetes
- ✅ Build and test your application locally
- ✅ Validate all services work correctly
- ✅ Test monitoring and health checks
- ✅ Verify configurations before GKE deployment

---

## 🔧 **Prerequisites Setup**

### **1. Install Docker Desktop with Kubernetes**

#### **Windows Installation**

```powershell
# Download Docker Desktop from: https://www.docker.com/products/docker-desktop
# During installation, ensure "Enable Kubernetes" is checked

# Verify installation
docker --version
docker-compose --version
kubectl version --client
```

#### **Enable Kubernetes in Docker Desktop**

1. Open **Docker Desktop**
2. Go to **Settings** → **Kubernetes**
3. Check **"Enable Kubernetes"**
4. Click **"Apply & Restart"**
5. Wait for Kubernetes to start (green indicator)

### **2. Verify Local Kubernetes Cluster**

```powershell
# Check cluster info
kubectl cluster-info

# Should show:
# Kubernetes control plane is running at https://kubernetes.docker.internal:6443
# CoreDNS is running at https://kubernetes.docker.internal:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# Check nodes
kubectl get nodes

# Should show something like:
# NAME             STATUS   ROLES           AGE   VERSION
# docker-desktop   Ready    control-plane   1d    v1.28.2
```

### **3. Configure kubectl for Local Context**

```powershell
# List available contexts
kubectl config get-contexts

# Switch to docker-desktop context (if not already active)
kubectl config use-context docker-desktop

# Verify current context
kubectl config current-context
# Should output: docker-desktop
```

---

## 🏗️ **Local Build and Test Process**

### **Step 1: Build Docker Images Locally**

```powershell
# Build all services for local testing
.\scripts\development\local-build.ps1

# Optional: Rebuild without cache
.\scripts\development\local-build.ps1 -Rebuild

# Optional: Skip container tests
.\scripts\development\local-build.ps1 -SkipTests
```

This script will:

- ✅ Build all microservices with local tags (`todo-app/SERVICE:local`)
- ✅ Verify images are created successfully
- ✅ Run basic container startup tests
- ✅ Prepare images for local Kubernetes deployment

### **Step 2: Deploy to Local Kubernetes**

```powershell
# Deploy complete application to local Kubernetes
.\scripts\development\deploy-local-k8s.ps1

# Optional: Clean deployment (removes existing resources)
.\scripts\development\deploy-local-k8s.ps1 -CleanDeploy

# Optional: Skip image building (use existing images)
.\scripts\development\deploy-local-k8s.ps1 -SkipBuild
```

This script will:

- ✅ Create `todo-app` namespace
- ✅ Deploy PostgreSQL and Redis databases
- ✅ Deploy all microservices (user-service, todo-service, notification-service)
- ✅ Deploy API Gateway and Frontend
- ✅ Configure health checks and service discovery
- ✅ Set up LoadBalancer services for external access

### **Step 3: Test Your Deployment**

```powershell
# Run comprehensive testing suite
.\scripts\development\test-local-deployment.ps1

# Optional: Verbose testing output
.\scripts\development\test-local-deployment.ps1 -Verbose
```

This script will:

- ✅ Check pod and service status
- ✅ Test inter-service connectivity
- ✅ Test external API endpoints
- ✅ Validate application functionality
- ✅ Provide troubleshooting information

---

## 🌍 **Accessing Your Local Application**

### **Automatic Access (LoadBalancer)**

If Docker Desktop automatically assigns ports:

```powershell
# Check assigned ports
kubectl get services -n todo-app

# Look for EXTERNAL-IP and PORT columns
```

### **Manual Port Forwarding**

If you need to manually forward ports:

```powershell
# Frontend access
kubectl port-forward -n todo-app svc/frontend-service 3000:80

# API Gateway access
kubectl port-forward -n todo-app svc/api-gateway-service 8080:8080

# Then access:
# Frontend: http://localhost:3000
# API: http://localhost:8080
```

---

## 🔍 **Monitoring and Debugging**

### **Check Application Status**

```powershell
# View all resources
kubectl get all -n todo-app

# Check pod logs
kubectl logs -f deployment/api-gateway -n todo-app
kubectl logs -f deployment/todo-service -n todo-app

# Check specific pod
kubectl describe pod POD-NAME -n todo-app
```

### **Test Database Connectivity**

```powershell
# Test PostgreSQL connection
kubectl exec -it deployment/postgres -n todo-app -- psql -U postgres -d todoapp -c "SELECT version();"

# Test Redis connection
kubectl exec -it deployment/redis -n todo-app -- redis-cli ping
```

### **Debug Service Issues**

```powershell
# Check service endpoints
kubectl get endpoints -n todo-app

# Test service connectivity from inside cluster
kubectl run debug-pod --image=busybox --rm -it -n todo-app -- sh
# Inside pod: wget -O- http://api-gateway-service:8080/health
```

---

## 🧪 **Testing Scenarios**

### **1. Basic Functionality Test**

1. **Access Frontend**: Navigate to http://localhost:3000
2. **Register User**: Create a new user account
3. **Login**: Authenticate with created credentials
4. **Create Todo**: Add a new todo item
5. **Manage Todos**: Edit, complete, and delete todos
6. **Test API**: Use http://localhost:8080/api endpoints

### **2. Service Integration Test**

1. **Health Checks**: Verify all `/health` endpoints return 200
2. **User Registration**: Test user service via API gateway
3. **Todo Operations**: Test todo service CRUD operations
4. **Notifications**: Test notification service integration
5. **Database Persistence**: Verify data persists across restarts

### **3. Performance Test**

```powershell
# Load test API endpoints (install if needed: choco install curl)
curl -X POST http://localhost:8080/api/auth/register -H "Content-Type: application/json" -d '{"username":"user1","email":"user1@test.com","password":"pass123"}'

# Test multiple concurrent requests
for ($i=1; $i -le 10; $i++) {
    Start-Job { curl http://localhost:8080/health }
}
```

---

## 🔧 **Troubleshooting Common Issues**

### **Issue: Pods Not Starting**

```powershell
# Check pod status and events
kubectl describe pod POD-NAME -n todo-app
kubectl get events -n todo-app --sort-by=.metadata.creationTimestamp

# Common fixes:
# 1. Rebuild images: .\scripts\development\local-build.ps1 -Rebuild
# 2. Check resource limits: kubectl top pods -n todo-app
# 3. Restart Docker Desktop
```

### **Issue: Services Not Accessible**

```powershell
# Check service configuration
kubectl get services -n todo-app
kubectl describe service SERVICE-NAME -n todo-app

# Test port forwarding manually
kubectl port-forward -n todo-app svc/frontend-service 3000:80
```

### **Issue: Database Connection Errors**

```powershell
# Check database pod logs
kubectl logs deployment/postgres -n todo-app
kubectl logs deployment/redis -n todo-app

# Verify secrets are created
kubectl get secrets -n todo-app
kubectl describe secret app-secrets -n todo-app
```

### **Issue: Image Pull Errors**

```powershell
# Verify images exist locally
docker images todo-app/*

# Rebuild if missing
.\scripts\development\local-build.ps1 -Rebuild

# Check imagePullPolicy is set to "Never" in deployments
kubectl describe deployment DEPLOYMENT-NAME -n todo-app
```

---

## 🚀 **Ready for Production?**

### **Pre-GKE Deployment Checklist**

- [ ] ✅ All pods running and healthy
- [ ] ✅ All services accessible via port-forward
- [ ] ✅ Frontend loads and displays correctly
- [ ] ✅ User registration and authentication works
- [ ] ✅ Todo CRUD operations function properly
- [ ] ✅ Database connectivity confirmed
- [ ] ✅ API endpoints respond correctly
- [ ] ✅ No error logs in pod outputs

### **When Tests Pass Successfully**

```powershell
# Clean up local deployment
kubectl delete namespace todo-app

# Deploy to production GKE
.\scripts\deployment\deploy-production.ps1 -PROJECT_ID "your-gcp-project" -DOMAIN_NAME "yourdomain.com"
```

---

## 📋 **Command Summary**

### **Complete Local Testing Workflow**

```powershell
# 1. Ensure Docker Desktop Kubernetes is enabled
kubectl config use-context docker-desktop

# 2. Build images locally
.\scripts\development\local-build.ps1

# 3. Deploy to local Kubernetes
.\scripts\development\deploy-local-k8s.ps1

# 4. Test deployment
.\scripts\development\test-local-deployment.ps1

# 5. Manual testing at http://localhost:3000

# 6. Clean up when ready
kubectl delete namespace todo-app

# 7. Deploy to GKE production
.\scripts\deployment\deploy-production.ps1 -PROJECT_ID "your-project" -DOMAIN_NAME "yourdomain.com"
```

---

## 🎯 **Benefits of Local Testing**

### **🔍 Validation Before Production**

- **Catch Issues Early**: Identify problems in controlled environment
- **Resource Verification**: Ensure proper resource allocation
- **Service Integration**: Validate microservices communicate correctly
- **Performance Baseline**: Establish performance expectations

### **💰 Cost Savings**

- **No Cloud Costs**: Test without GKE charges
- **Rapid Iteration**: Quick feedback loop for fixes
- **Debugging Ease**: Full control over local environment
- **Network Access**: No internet dependency for testing

### **🚀 Confidence Building**

- **Deployment Verification**: Prove deployment scripts work
- **Feature Validation**: Confirm all functionality works
- **Team Alignment**: Share working version with team
- **Production Readiness**: High confidence for GKE deployment

---

**🎉 With this local testing approach, you can confidently validate your entire application stack before deploying to production GKE, ensuring a smooth and successful production deployment!**

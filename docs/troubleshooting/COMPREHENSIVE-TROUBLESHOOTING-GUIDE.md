# 🔧 Comprehensive Troubleshooting Guide

**Last Updated:** October 21, 2025

This guide consolidates all troubleshooting scenarios encountered during the development and deployment of the Todo Microservices application.

---

## 📑 Table of Contents

1. [CORS Issues](#cors-issues)
2. [Port Conflicts](#port-conflicts)
3. [Kubernetes Pod Issues](#kubernetes-pod-issues)
4. [Database Connection Issues](#database-connection-issues)
5. [Image Pull Issues](#image-pull-issues)
6. [Frontend Build Issues](#frontend-build-issues)
7. [Service Discovery Issues](#service-discovery-issues)
8. [Authentication Issues](#authentication-issues)
9. [Network/Connectivity Issues](#networkconnectivity-issues)
10. [Resource Issues](#resource-issues)

---

## 🔴 CORS Issues

### Issue 1: CORS Blocked - localhost:3000

**Symptoms:**

```
Access to XMLHttpRequest at 'http://localhost:8080/api/auth/register'
from origin 'http://localhost:3000' has been blocked by CORS policy
```

**Root Cause:**

- API Gateway's `ALLOWED_ORIGINS` doesn't include `http://localhost:3000`
- Only configured for Kubernetes internal service names

**Solution:**

1. **Update API Gateway ConfigMap:**

```yaml
# k8s/simple/api-gateway-deployment.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-gateway-config
  namespace: todo-app
data:
  ALLOWED_ORIGINS: "http://frontend-service,http://frontend-service:80,http://localhost:3000"
```

2. **Apply changes:**

```powershell
kubectl apply -f k8s/simple/api-gateway-deployment.yaml
kubectl rollout restart deployment/api-gateway -n todo-app
```

3. **Verify:**

```powershell
kubectl logs deployment/api-gateway -n todo-app --tail=20
# Should show: "Frontend URL: http://localhost:3000"
```

---

### Issue 2: 405 Not Allowed When Calling API

**Symptoms:**

```
POST http://localhost:3000/api/auth/register 405 (Not Allowed)
```

**Root Cause:**

- Frontend making requests to `localhost:3000/api` instead of `localhost:8080/api`
- Frontend Docker image built with `REACT_APP_API_URL="/api"` (relative path)
- Relative path resolves to frontend's own address when accessing via port-forward

**Solution:**

1. **Rebuild frontend with absolute URL:**

```powershell
cd frontend
docker build -t frontend:latest -t frontend:dev `
  --build-arg REACT_APP_API_URL="http://localhost:8080/api" .
```

2. **Deploy updated frontend:**

```powershell
kubectl rollout restart deployment/frontend -n todo-app
kubectl rollout status deployment/frontend -n todo-app
```

3. **Verify fix:**

- Check network tab in browser - requests should go to `http://localhost:8080/api`
- No more 405 errors

**Note:** For production with Ingress, use `REACT_APP_API_URL="/api"` (relative path)

---

### Issue 3: CORS Errors After Clearing Browser Cache

**Symptoms:**

- CORS errors reappear after clearing browser cache
- Hard refresh causes CORS issues

**Root Cause:**

- Browser not sending credentials/cookies
- Preflight OPTIONS requests failing

**Solution:**

1. **Ensure API Gateway handles OPTIONS requests:**

```typescript
// api-gateway/src/index.ts
app.options("*", cors(corsOptions));
```

2. **Check CORS configuration includes credentials:**

```typescript
const corsOptions = {
  origin: allowedOrigins,
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
};
```

3. **Frontend must send credentials:**

```typescript
// frontend/src/services/api.ts
axios.defaults.withCredentials = true;
```

---

## ⚠️ Port Conflicts

### Issue 1: Port 8080 Already in Use

**Symptoms:**

```
Error: listen EADDRINUSE: address already in use :::8080
```

**Root Cause:**

- Apache, Tomcat, or another service using port 8080
- Old kubectl port-forward process still running

**Solution:**

1. **Find process using port:**

```powershell
Get-NetTCPConnection -LocalPort 8080 -State Listen |
  Select-Object OwningProcess |
  Get-Unique |
  ForEach-Object { Get-Process -Id $_.OwningProcess }
```

2. **Kill the process:**

```powershell
Stop-Process -Id <PID> -Force
```

3. **Or use alternative port:**

```powershell
# Use port 8081 instead
kubectl port-forward svc/api-gateway-service 8081:8080 -n todo-app
```

Then update frontend: `REACT_APP_API_URL="http://localhost:8081/api"`

---

### Issue 2: Port Forwarding Fails - Address Already in Use

**Symptoms:**

```
Unable to listen on port 3000: Only one usage of each socket address
(protocol/network address/port) is normally permitted.
```

**Root Cause:**

- Old kubectl port-forward process holding the port

**Solution:**

1. **Kill all kubectl port-forward processes:**

```powershell
Get-Process kubectl | Stop-Process -Force
```

2. **Restart port forwarding:**

```powershell
kubectl port-forward svc/frontend-service 3000:80 -n todo-app
kubectl port-forward svc/api-gateway-service 8080:8080 -n todo-app
```

---

## ☸️ Kubernetes Pod Issues

### Issue 1: ImagePullBackOff - Multi-Node Cluster

**Symptoms:**

```
NAME                                    READY   STATUS             RESTARTS   AGE
notification-service-xxxxx-xxxxx       0/1     ImagePullBackOff   0          2m
```

**Root Cause:**

- Docker Desktop Kubernetes has multi-node setup (control-plane + worker)
- Local images only available on control-plane node
- Pod scheduled on worker node can't find image

**Solution:**

**Option A: Force pod to control-plane node**

```yaml
# Add to deployment spec
spec:
  template:
    spec:
      nodeSelector:
        node-role.kubernetes.io/control-plane: ""
```

**Option B: Change imagePullPolicy**

```yaml
spec:
  template:
    spec:
      containers:
        - name: notification-service
          image: notification-service:latest
          imagePullPolicy: IfNotPresent # Change from Never
```

**Option C: Load image on all nodes**

```powershell
# Save image
docker save notification-service:latest -o notification-service.tar

# Load on worker node
docker exec desktop-worker ctr -n k8s.io images import notification-service.tar
```

**Verify fix:**

```powershell
kubectl get pods -n todo-app
# All pods should show Running status
```

---

### Issue 2: CrashLoopBackOff - Application Error

**Symptoms:**

```
NAME                           READY   STATUS             RESTARTS   AGE
user-service-xxxxx-xxxxx      0/1     CrashLoopBackOff   5          10m
```

**Root Cause:**

- Application failing to start
- Database connection error
- Missing environment variables
- Code error

**Solution:**

1. **Check logs:**

```powershell
kubectl logs pod-name -n todo-app
kubectl logs pod-name -n todo-app --previous  # Previous crash
```

2. **Common fixes:**

**Database not ready:**

```powershell
# Check postgres is running
kubectl get pods -l app=postgres -n todo-app

# Add init container to wait for DB
spec:
  initContainers:
  - name: wait-for-postgres
    image: busybox:1.28
    command: ['sh', '-c', 'until nc -z postgres-service 5432; do echo waiting for postgres; sleep 2; done']
```

**Missing environment variables:**

```powershell
kubectl describe pod pod-name -n todo-app
# Check Environment section
```

**Fix ConfigMap and restart:**

```powershell
kubectl apply -f k8s/simple/service-deployment.yaml
kubectl rollout restart deployment/service-name -n todo-app
```

---

### Issue 3: Pending Pods - Resource Constraints

**Symptoms:**

```
NAME                           READY   STATUS    RESTARTS   AGE
todo-service-xxxxx-xxxxx      0/1     Pending   0          5m
```

**Root Cause:**

- Insufficient CPU/memory resources
- PersistentVolumeClaim not bound
- Node selector/affinity not satisfied

**Solution:**

1. **Describe pod to see reason:**

```powershell
kubectl describe pod pod-name -n todo-app
```

2. **Check events:**

```powershell
kubectl get events -n todo-app --sort-by='.lastTimestamp'
```

3. **Fix resource limits:**

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

4. **Check node resources:**

```powershell
kubectl top nodes
kubectl describe nodes
```

---

## 💾 Database Connection Issues

### Issue 1: Can't Connect to PostgreSQL

**Symptoms:**

```
Error: connect ECONNREFUSED postgres-service:5432
FATAL: password authentication failed for user "postgres"
```

**Root Cause:**

- PostgreSQL not running
- Wrong connection string
- Incorrect credentials
- Service name mismatch

**Solution:**

1. **Verify PostgreSQL is running:**

```powershell
kubectl get pods -l app=postgres -n todo-app
kubectl logs deployment/postgres -n todo-app
```

2. **Check service:**

```powershell
kubectl get svc postgres-service -n todo-app
```

3. **Verify environment variables:**

```powershell
kubectl get configmap user-service-config -n todo-app -o yaml
kubectl get secret user-service-secret -n todo-app -o yaml
```

4. **Test connection from pod:**

```powershell
kubectl exec -it deployment/user-service -n todo-app -- sh
nc -zv postgres-service 5432
# Or
ping postgres-service
```

5. **Correct connection string format:**

```
postgresql://username:password@postgres-service:5432/database
```

---

### Issue 2: Database Schema Not Created

**Symptoms:**

```
Error: relation "users" does not exist
```

**Root Cause:**

- Migrations not run
- Init scripts not executed
- Wrong database selected

**Solution:**

1. **Check if tables exist:**

```powershell
kubectl exec -it deployment/postgres -n todo-app -- psql -U postgres -d todoapp -c "\dt"
```

2. **Run migrations manually:**

```powershell
kubectl exec -it deployment/user-service -n todo-app -- npm run migrate
```

3. **Or add init container to run migrations:**

```yaml
initContainers:
  - name: run-migrations
    image: user-service:latest
    command: ["npm", "run", "migrate"]
    env:
      - name: DATABASE_URL
        value: "postgresql://postgres:password@postgres-service:5432/todoapp"
```

---

## 🖼️ Image Pull Issues

### Issue 1: Image Not Found Locally

**Symptoms:**

```
Failed to pull image "frontend:latest": rpc error: image not found
```

**Root Cause:**

- Image not built
- Wrong image tag
- Image deleted

**Solution:**

1. **Verify image exists:**

```powershell
docker images | Select-String "frontend"
```

2. **Build image:**

```powershell
cd frontend
docker build -t frontend:latest .
```

3. **Check deployment uses correct tag:**

```yaml
spec:
  containers:
    - name: frontend
      image: frontend:latest # Must match
      imagePullPolicy: IfNotPresent
```

---

### Issue 2: Wrong Image Registry

**Symptoms:**

```
Failed to pull image "gcr.io/project/frontend:latest": not found
```

**Root Cause:**

- Image not pushed to registry
- Wrong registry URL
- Authentication failed

**Solution:**

1. **For local development, use local images:**

```yaml
image: frontend:latest
imagePullPolicy: IfNotPresent # Don't try to pull
```

2. **For GKE, push to GCR:**

```bash
docker tag frontend:latest gcr.io/$PROJECT_ID/frontend:latest
docker push gcr.io/$PROJECT_ID/frontend:latest
```

3. **Update deployment:**

```yaml
image: gcr.io/your-project/frontend:latest
imagePullPolicy: Always
```

---

## 🎨 Frontend Build Issues

### Issue 1: Environment Variables Not Working

**Symptoms:**

- Frontend calls wrong API URL
- Environment variables undefined in browser

**Root Cause:**

- React bakes environment variables at build time
- Environment variables set at runtime don't affect React app
- Must rebuild with correct `REACT_APP_*` variables

**Solution:**

1. **Set build args when building Docker image:**

```dockerfile
# Dockerfile
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL
RUN npm run build
```

2. **Build with correct URL:**

```powershell
# For port-forward testing
docker build -t frontend:latest --build-arg REACT_APP_API_URL="http://localhost:8080/api" ./frontend

# For production with ingress
docker build -t frontend:latest --build-arg REACT_APP_API_URL="/api" ./frontend
```

3. **Verify in running container:**

```powershell
kubectl exec -it deployment/frontend -n todo-app -- sh
cat /usr/share/nginx/html/static/js/main.*.js | grep "localhost:8080"
```

---

### Issue 2: Nginx 405 Not Allowed for /api

**Symptoms:**

```
POST http://localhost:3000/api/auth/register 405 (Not Allowed)
```

**Root Cause:**

- Nginx serving frontend doesn't have proxy for `/api`
- Requests to `/api` hit nginx directly instead of API Gateway

**Solution:**

**Option A: Use absolute URL (for port-forward)**

Build frontend with full API Gateway URL:

```powershell
docker build --build-arg REACT_APP_API_URL="http://localhost:8080/api" .
```

**Option B: Add nginx proxy configuration**

```nginx
# nginx.conf
location /api {
    proxy_pass http://api-gateway-service:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
}
```

---

## 🔍 Service Discovery Issues

### Issue 1: Service Name Not Resolving

**Symptoms:**

```
Error: getaddrinfo ENOTFOUND user-service
```

**Root Cause:**

- Service not created
- Wrong namespace
- Service name typo

**Solution:**

1. **Verify service exists:**

```powershell
kubectl get svc -n todo-app
```

2. **Check service has endpoints:**

```powershell
kubectl get endpoints user-service -n todo-app
```

3. **Use full DNS name if cross-namespace:**

```
http://service-name.namespace.svc.cluster.local:port
Example: http://user-service.todo-app.svc.cluster.local:3002
```

4. **Test DNS resolution:**

```powershell
kubectl exec -it deployment/api-gateway -n todo-app -- nslookup user-service
```

---

### Issue 2: Wrong Service Port

**Symptoms:**

```
Error: connect ECONNREFUSED user-service:3000
```

**Root Cause:**

- Service listening on different port than configured
- Service port vs target port mismatch

**Solution:**

1. **Check service configuration:**

```powershell
kubectl describe svc user-service -n todo-app
```

2. **Verify port mapping:**

```yaml
apiVersion: v1
kind: Service
spec:
  ports:
    - port: 3002 # Port service listens on
      targetPort: 3000 # Port container listens on
```

3. **Ensure environment variables match:**

```yaml
# Service deployment
env:
  - name: PORT
    value: "3000" # Must match container port

  # API Gateway connection
  - name: USER_SERVICE_URL
    value: "http://user-service:3002" # Must match service port
```

---

## 🔐 Authentication Issues

### Issue 1: JWT Token Invalid

**Symptoms:**

```
Error: invalid token
Error: jwt malformed
```

**Root Cause:**

- JWT_SECRET mismatch between services
- Token expired
- Token format incorrect

**Solution:**

1. **Ensure all services use same JWT_SECRET:**

```powershell
# Check secrets
kubectl get secret user-service-secret -n todo-app -o yaml
kubectl get secret api-gateway-secret -n todo-app -o yaml

# Decode and compare
kubectl get secret user-service-secret -n todo-app -o jsonpath='{.data.JWT_SECRET}' | base64 --decode
```

2. **Update all secrets with same value:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: service-secret
type: Opaque
stringData:
  JWT_SECRET: "local-dev-secret-key-change-in-production"
```

3. **Restart all services:**

```powershell
kubectl rollout restart deployment/user-service -n todo-app
kubectl rollout restart deployment/todo-service -n todo-app
kubectl rollout restart deployment/api-gateway -n todo-app
```

---

### Issue 2: Authentication Headers Not Forwarded

**Symptoms:**

```
Error: No authorization header
Error: Unauthorized
```

**Root Cause:**

- API Gateway not forwarding Authorization header
- CORS not allowing Authorization header

**Solution:**

1. **Check API Gateway proxy configuration:**

```typescript
// api-gateway/src/index.ts
app.use(
  "/api/todos",
  createProxyMiddleware({
    target: TODO_SERVICE_URL,
    changeOrigin: true,
    pathRewrite: { "^/api/todos": "/api/todos" },
    onProxyReq: (proxyReq, req) => {
      // Forward auth header
      if (req.headers.authorization) {
        proxyReq.setHeader("Authorization", req.headers.authorization);
      }
    },
  })
);
```

2. **Update CORS to allow Authorization header:**

```typescript
const corsOptions = {
  origin: allowedOrigins,
  credentials: true,
  allowedHeaders: ["Content-Type", "Authorization"], // Add Authorization
};
```

---

## 🌐 Network/Connectivity Issues

### Issue 1: Can't Access Application from Browser

**Symptoms:**

- Port forwarding set up but browser shows "Can't reach this page"

**Root Cause:**

- Port forwarding not running
- Wrong port
- Process killed

**Solution:**

1. **Check if port-forward is running:**

```powershell
Get-Process kubectl
```

2. **Check terminal output:**
   Should see: `Forwarding from 127.0.0.1:3000 -> 80`

3. **Restart port forwarding:**

```powershell
kubectl port-forward svc/frontend-service 3000:80 -n todo-app
```

4. **Try different port if conflict:**

```powershell
kubectl port-forward svc/frontend-service 3001:80 -n todo-app
# Access at localhost:3001
```

---

### Issue 2: Request Timeout

**Symptoms:**

```
Error: Request failed with timeout
Error: ETIMEDOUT
```

**Root Cause:**

- Service not responding
- Container not ready
- Network policy blocking

**Solution:**

1. **Check pod readiness:**

```powershell
kubectl get pods -n todo-app
# All should show 1/1 READY
```

2. **Check pod logs:**

```powershell
kubectl logs deployment/service-name -n todo-app
```

3. **Test connectivity:**

```powershell
kubectl exec -it deployment/api-gateway -n todo-app -- curl -v http://user-service:3002/health
```

4. **Check network policies:**

```powershell
kubectl get networkpolicies -n todo-app
```

---

## 📊 Resource Issues

### Issue 1: Out of Memory - Pod Killed

**Symptoms:**

```
NAME                     READY   STATUS      RESTARTS   AGE
frontend-xxxxx-xxxxx    0/1     OOMKilled   1          2m
```

**Root Cause:**

- Memory limit too low
- Memory leak in application
- Too many concurrent requests

**Solution:**

1. **Increase memory limits:**

```yaml
resources:
  requests:
    memory: "256Mi"
  limits:
    memory: "512Mi" # Increase
```

2. **Check memory usage:**

```powershell
kubectl top pods -n todo-app
```

3. **Investigate memory leak:**

```powershell
kubectl exec -it deployment/service-name -n todo-app -- node --inspect
# Use Chrome DevTools to profile
```

---

### Issue 2: CPU Throttling

**Symptoms:**

- Application slow
- High CPU usage
- Requests timing out

**Root Cause:**

- CPU limit too low
- Inefficient code
- Too many replicas on same node

**Solution:**

1. **Check CPU usage:**

```powershell
kubectl top pods -n todo-app
kubectl top nodes
```

2. **Increase CPU limits:**

```yaml
resources:
  requests:
    cpu: "200m"
  limits:
    cpu: "500m" # Increase
```

3. **Add horizontal pod autoscaling:**

```powershell
kubectl autoscale deployment service-name --cpu-percent=80 --min=2 --max=5 -n todo-app
```

---

## 🔄 Quick Reference Commands

### Pod Troubleshooting

```powershell
# Get pods status
kubectl get pods -n todo-app

# Describe pod (shows events)
kubectl describe pod pod-name -n todo-app

# Get logs
kubectl logs pod-name -n todo-app
kubectl logs pod-name -n todo-app --previous  # Previous container
kubectl logs -f pod-name -n todo-app  # Follow logs

# Execute command in pod
kubectl exec -it pod-name -n todo-app -- sh

# Get pod yaml
kubectl get pod pod-name -n todo-app -o yaml
```

### Service Troubleshooting

```powershell
# Get services
kubectl get svc -n todo-app

# Describe service
kubectl describe svc service-name -n todo-app

# Get endpoints
kubectl get endpoints service-name -n todo-app

# Test connectivity
kubectl exec -it deployment/api-gateway -n todo-app -- curl http://service-name:port/health
```

### Configuration Troubleshooting

```powershell
# Get ConfigMaps
kubectl get configmap -n todo-app
kubectl describe configmap config-name -n todo-app
kubectl get configmap config-name -n todo-app -o yaml

# Get Secrets
kubectl get secret -n todo-app
kubectl describe secret secret-name -n todo-app
kubectl get secret secret-name -n todo-app -o jsonpath='{.data.KEY}' | base64 --decode
```

### Deployment Troubleshooting

```powershell
# Get deployments
kubectl get deployments -n todo-app

# Describe deployment
kubectl describe deployment deployment-name -n todo-app

# Rollout status
kubectl rollout status deployment/deployment-name -n todo-app

# Rollout history
kubectl rollout history deployment/deployment-name -n todo-app

# Rollback
kubectl rollout undo deployment/deployment-name -n todo-app

# Restart deployment
kubectl rollout restart deployment/deployment-name -n todo-app
```

### Events & Logs

```powershell
# Get events (sorted)
kubectl get events -n todo-app --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n todo-app -w

# All logs from deployment
kubectl logs deployment/deployment-name -n todo-app --all-containers=true
```

---

## 📞 Getting Help

When seeking help, include:

1. **Exact error message** - Full text from logs
2. **Pod status** - Output of `kubectl get pods -n todo-app`
3. **Pod events** - Output of `kubectl describe pod pod-name -n todo-app`
4. **Service logs** - Output of `kubectl logs pod-name -n todo-app`
5. **Configuration** - Relevant ConfigMap/Secret values (redact sensitive data)
6. **What you've tried** - Previous troubleshooting steps

---

**This guide is continuously updated as new issues are encountered and resolved.**

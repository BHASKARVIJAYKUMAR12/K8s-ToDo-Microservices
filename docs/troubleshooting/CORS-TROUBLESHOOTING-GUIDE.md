# CORS Configuration & Troubleshooting Guide

## 📋 Overview

This guide covers CORS (Cross-Origin Resource Sharing) configuration and troubleshooting for the Todo Microservices application.

## 🎯 Problem Description

The frontend application encounters CORS errors when making API requests:

```
Access to XMLHttpRequest at 'http://localhost:8080/api/auth/register' from origin 'http://localhost:3000'
has been blocked by CORS policy: Response to preflight request doesn't pass access control check:
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## 🔍 Root Causes

### 1. Incorrect CORS Callback Implementation

- Using `callback(null, true)` instead of `callback(null, origin)`
- This doesn't reflect the requesting origin in the response header

### 2. Port Conflicts

- Port 8080 may be occupied by other services (Apache, IIS on Windows)
- Inconsistent port configuration between frontend and API gateway

### 3. Missing Environment Configuration

- No proper `.env` files for development
- Hardcoded URLs causing mismatches

### 4. Docker Build Cache Issues

- Configuration changes not reflected due to cached layers

## ✅ Complete Solution

### 1. API Gateway CORS Configuration

Update `api-gateway/src/index.ts`:

```typescript
const allowedOrigins = [
  "http://frontend-service", // Kubernetes service name
  "http://localhost:3000", // Local React dev server
  "http://127.0.0.1:3000", // Alternative localhost
  "http://frontend-service:80", // Kubernetes service with port
];

app.use(
  cors({
    origin: function (origin, callback) {
      // Allow requests with no origin (mobile apps, curl)
      if (!origin) return callback(null, true);

      if (
        allowedOrigins.indexOf(origin) !== -1 ||
        process.env.NODE_ENV === "development"
      ) {
        // ✅ KEY FIX: Return the requesting origin, not just 'true'
        callback(null, origin);
      } else {
        console.warn(`CORS blocked origin: ${origin}`);
        callback(new Error("Not allowed by CORS"));
      }
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
    exposedHeaders: ["Content-Range", "X-Content-Range"],
    maxAge: 600, // Cache preflight for 10 minutes
  })
);
```

### 2. Frontend API Configuration

Update `frontend/src/services/api.ts`:

```typescript
const API_BASE_URL =
  process.env.REACT_APP_API_URL || "http://localhost:8080/api";

const api = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
  timeout: 10000,
  headers: {
    "Content-Type": "application/json",
  },
});
```

### 3. Environment Configuration

Create `.env.local` files:

**Frontend** (`frontend/.env.local`):

```env
REACT_APP_API_URL=http://localhost:8080/api
```

**API Gateway** (`api-gateway/.env.local`):

```env
PORT=8080
NODE_ENV=development
TODO_SERVICE_URL=http://localhost:3001
USER_SERVICE_URL=http://localhost:3002
NOTIFICATION_SERVICE_URL=http://localhost:3003
ALLOWED_ORIGINS=http://localhost:3000
JWT_SECRET=local-dev-secret-key-change-in-production
```

## 🚀 Deployment Steps

### 1. Rebuild with No Cache

```powershell
# API Gateway
docker build --no-cache -t todo-app/api-gateway:local ./api-gateway

# Frontend
docker build --no-cache -t todo-app/frontend:local ./frontend
```

### 2. Restart Kubernetes Pods

```powershell
# Delete pods to force recreation with new images
kubectl delete pod -n todo-app -l app=api-gateway
kubectl delete pod -n todo-app -l app=frontend

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=api-gateway -n todo-app --timeout=60s
kubectl wait --for=condition=ready pod -l app=frontend -n todo-app --timeout=60s
```

### 3. Setup Port Forwards

```powershell
# API Gateway (standard port 8080)
Start-Process powershell -WindowStyle Minimized -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n todo-app svc/api-gateway-service 8080:8080"

# Frontend
Start-Process powershell -WindowStyle Minimized -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n todo-app svc/frontend-service 3000:80"
```

**Note:** If port 8080 is occupied, use port 8081:

```powershell
kubectl port-forward -n todo-app svc/api-gateway-service 8081:8080
```

And update frontend environment: `REACT_APP_API_URL=http://localhost:8081/api`

## 🧪 Testing & Verification

### 1. Clear Browser Cache

- Press **Ctrl + Shift + R** for hard refresh
- Or **F12** → Right-click Refresh → "Empty Cache and Hard Reload"

### 2. Test CORS Preflight

```powershell
curl.exe -X OPTIONS -H "Origin: http://localhost:3000" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: Content-Type" -v http://localhost:8080/api/auth/register
```

**Expected Response Headers:**

```
Access-Control-Allow-Origin: http://localhost:3000
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET,POST,PUT,DELETE,PATCH,OPTIONS
Access-Control-Allow-Headers: Content-Type,Authorization
```

### 3. Test Service Health

```powershell
# API Gateway
curl.exe http://localhost:8080/health
# Expected: {"status":"healthy","service":"api-gateway"}

# Frontend
curl.exe http://localhost:3000
# Expected: HTML with "Todo App" title
```

### 4. Browser Testing

1. Open http://localhost:3000
2. Open DevTools (F12) → Network tab
3. Try user registration:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `password123`
4. Verify in Network tab:
   - ✅ Request to `http://localhost:8080/api/auth/register`
   - ✅ Status: `201 Created`
   - ✅ Response headers include CORS headers
   - ✅ No CORS errors in Console

## 🔧 Troubleshooting

### CORS Errors Still Occur

1. **Clear Browser Cache Completely**

   ```javascript
   // In Browser Console (F12)
   localStorage.clear();
   sessionStorage.clear();
   // Then hard refresh (Ctrl+Shift+R)
   ```

2. **Verify Port Forwarding**

   ```powershell
   Get-Process | Where-Object {$_.ProcessName -eq "kubectl"}
   ```

3. **Check API Gateway Logs**

   ```powershell
   kubectl logs -f deployment/api-gateway -n todo-app
   ```

4. **Verify Pod Image**
   ```powershell
   kubectl describe pod -l app=api-gateway -n todo-app | Select-String "Image:"
   ```

### Port Conflicts

1. **Check Port Usage**

   ```powershell
   netstat -ano | findstr :8080
   ```

2. **Stop Conflicting Services**

   ```powershell
   # Stop Apache/IIS if running
   net stop apache
   iisreset /stop
   ```

3. **Use Alternative Port**
   ```powershell
   kubectl port-forward -n todo-app svc/api-gateway-service 8081:8080
   ```

## 📊 Port Configuration Reference

| Service              | Local Port | Kubernetes Port | Purpose               |
| -------------------- | ---------- | --------------- | --------------------- |
| Frontend             | 3000       | 80              | React UI              |
| API Gateway          | 8080       | 8080            | **Main entry point**  |
| Todo Service         | 3001       | 3001            | Todo CRUD operations  |
| User Service         | 3002       | 3002            | Authentication        |
| Notification Service | 3003       | 3003            | Notifications         |
| PostgreSQL           | 5432       | 5432            | Database              |
| Redis                | 6379       | 6379            | Cache & message queue |

**Important:** Frontend should ONLY communicate with API Gateway (port 8080/8081).

## 🎓 Key Learnings

1. **CORS Callback**: Always use `callback(null, origin)` for multiple allowed origins
2. **Docker Cache**: Use `--no-cache` for configuration changes
3. **Port Conflicts**: Check for Apache, IIS, or other services on Windows
4. **Browser Cache**: Always hard refresh after frontend changes
5. **Environment Variables**: Use `.env.local` for development configuration

## ✅ Success Indicators

- ✅ No CORS errors in browser console
- ✅ Successful API responses (201, 200 status codes)
- ✅ Proper CORS headers in response
- ✅ All CRUD operations work
- ✅ User registration and login functional

## 📞 Quick Reference Commands

```powershell
# Check services
kubectl get pods -n todo-app
kubectl get svc -n todo-app

# Restart API Gateway
kubectl rollout restart deployment/api-gateway -n todo-app

# View logs
kubectl logs -f deployment/api-gateway -n todo-app

# Test endpoints
curl.exe http://localhost:8080/health
curl.exe -X POST http://localhost:8080/api/auth/register -H "Content-Type: application/json" -d "{\"username\":\"test\",\"email\":\"test@test.com\",\"password\":\"password123\"}"
```

---

**Status:** ✅ **Complete CORS Solution**  
**Last Updated:** October 24, 2025  
**Environment:** Docker Desktop Kubernetes + Local Development

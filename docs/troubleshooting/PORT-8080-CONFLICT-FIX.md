# 🔧 Port 8080 Conflict - Quick Fix

## 🐛 Problem

Port 8080 is already in use by Apache HTTP server (httpd) running on your system, preventing `kubectl port-forward` from using that port.

```
Error: unable to listen on port 8080: bind: An attempt was made to access a socket in a way forbidden by its access permissions.
```

---

## ✅ Solution Applied

**Using Alternative Port:** Instead of port 8080, we're using **port 8081** for the API Gateway.

### Current Port Forwarding:

- ✅ **Frontend:** http://localhost:3000 → frontend-service:80
- ✅ **API Gateway:** http://localhost:8081 → api-gateway-service:8080

---

## 🔧 Option 1: Use Port 8081 (Recommended - Already Active)

### Update Frontend API URL

You have **two options**:

### **A. Use Environment Variable (Easiest)**

Create a file `.env` in the `frontend` folder:

```env
REACT_APP_API_URL=http://localhost:8081/api
```

Then restart your frontend port-forward:

```powershell
# Kill existing port-forward
Get-Process kubectl -ErrorAction SilentlyContinue | Stop-Process -Force

# Restart both port-forwards
kubectl port-forward -n todo-app svc/api-gateway-service 8081:8080 &
kubectl port-forward -n todo-app svc/frontend-service 3000:80
```

### **B. Update API Configuration in Code**

Edit `frontend/src/services/api.ts`:

```typescript
const API_BASE_URL =
  process.env.REACT_APP_API_URL || "http://localhost:8081/api"; // Changed from 8080 to 8081
```

Then rebuild frontend:

```powershell
docker build -t todo-app/frontend:local ./frontend
kubectl rollout restart deployment/frontend -n todo-app
```

---

## 🔧 Option 2: Free Up Port 8080 (Advanced)

### Stop Apache HTTP Server

If you don't need Apache running:

```powershell
# Find Apache service
Get-Service | Where-Object {$_.DisplayName -like "*Apache*"}

# Stop Apache service (adjust name if different)
Stop-Service -Name "Apache2.4" -Force

# Or kill the process
Stop-Process -Name "httpd" -Force
```

Then restart port-forward on 8080:

```powershell
kubectl port-forward -n todo-app svc/api-gateway-service 8080:8080
```

---

## 🚀 Quick Start (Using Port 8081)

### 1. Verify Port Forwards are Running

```powershell
# Check active port forwards
Get-Process kubectl -ErrorAction SilentlyContinue

# You should see 2 kubectl processes (one for each port-forward)
```

### 2. Test API Gateway

```powershell
curl.exe http://localhost:8081/health
```

**Expected:**

```json
{
  "status": "healthy",
  "timestamp": "2025-10-17T10:28:20.505Z",
  "service": "api-gateway"
}
```

### 3. Test Frontend

Open your browser: http://localhost:3000

### 4. Update Frontend API URL (In Browser Console)

Since the frontend is already built and expects port 8080, you can temporarily override it:

**Open Browser Console (F12) and run:**

```javascript
// Override API base URL
localStorage.setItem("API_BASE_URL", "http://localhost:8081/api");
// Reload page
location.reload();
```

**Or use a browser extension like ModHeader to redirect:**

- Redirect `localhost:8080` → `localhost:8081`

---

## 📋 Complete Setup with Port 8081

### PowerShell Script to Start Everything

```powershell
# Kill any existing port-forwards
Get-Process kubectl -ErrorAction SilentlyContinue | Stop-Process -Force

# Wait for cleanup
Start-Sleep -Seconds 2

# Start API Gateway port-forward (using 8081)
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n todo-app svc/api-gateway-service 8081:8080"

# Start Frontend port-forward
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n todo-app svc/frontend-service 3000:80"

# Wait for port-forwards to start
Start-Sleep -Seconds 3

# Test connections
Write-Host "`n=== Testing Connections ===" -ForegroundColor Cyan
Write-Host "API Gateway: " -NoNewline
curl.exe -s http://localhost:8081/health | Out-Null
if ($?) { Write-Host "✅ OK" -ForegroundColor Green } else { Write-Host "❌ Failed" -ForegroundColor Red }

Write-Host "Frontend: " -NoNewline
curl.exe -s http://localhost:3000 -o $null
if ($?) { Write-Host "✅ OK" -ForegroundColor Green } else { Write-Host "❌ Failed" -ForegroundColor Red }

Write-Host "`n=== Access URLs ===" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Yellow
Write-Host "API Gateway: http://localhost:8081" -ForegroundColor Yellow
Write-Host "`n⚠️  Note: Frontend expects API on port 8080, but we're using 8081" -ForegroundColor Yellow
Write-Host "Use browser console workaround or rebuild frontend with correct port." -ForegroundColor Yellow
```

**Save as:** `start-port-forwards.ps1`

**Run:**

```powershell
.\start-port-forwards.ps1
```

---

## 🎯 Recommended Solution: Browser Proxy

The easiest way without rebuilding is to use a **browser extension**:

### Chrome/Edge: Use "Requestly" Extension

1. Install: [Requestly](https://chrome.google.com/webstore/detail/requestly/mdnleldcmiljblolnjhpnblkcekpdkpa)
2. Create a redirect rule:
   - **Source:** `http://localhost:8080/*`
   - **Destination:** `http://localhost:8081/$1`
3. Enable the rule
4. Refresh http://localhost:3000

Now all API calls will automatically redirect from 8080 → 8081!

---

## 🔍 Debugging Port Issues

### Check What's Using a Port

```powershell
# Check port 8080
Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue |
  Select-Object LocalPort, State, OwningProcess |
  ForEach-Object {
    $_ | Add-Member -NotePropertyName ProcessName -NotePropertyValue (Get-Process -Id $_.OwningProcess).ProcessName -PassThru
  }

# Or using netstat
netstat -ano | Select-String ":8080"
```

### Kill a Process by Port

```powershell
# Find and kill process on port 8080
$proc = Get-NetTCPConnection -LocalPort 8080 -State Listen | Select-Object -First 1 -ExpandProperty OwningProcess
Stop-Process -Id $proc -Force
```

### List All Port Forwards

```powershell
Get-Process kubectl | Select-Object Id, ProcessName, StartTime
```

---

## ✅ Current Status

- ✅ API Gateway accessible at: http://localhost:8081
- ✅ Frontend accessible at: http://localhost:3000
- ⚠️ Frontend needs to call API at 8081 instead of 8080

**Next Step:** Choose one of the solutions above to make frontend call the correct API port.

---

## 🚀 Quick Test

```powershell
# Test API directly
curl.exe -X POST http://localhost:8081/api/auth/register `
  -H "Content-Type: application/json" `
  -d '{\"username\":\"testuser\",\"email\":\"test@example.com\",\"password\":\"password123\"}'
```

---

**💡 Tip:** The browser proxy/redirect method is the fastest solution without rebuilding anything!

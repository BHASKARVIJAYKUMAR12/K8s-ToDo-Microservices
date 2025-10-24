# 🚀 Quick Start Reference Card

## 🎯 Essential Information

**Frontend connects to**: `http://localhost:8080/api` (API Gateway ONLY)  
**Main ports**: Frontend (3000), API Gateway (8080), Backend services (3001-3003)

---

## ⚡ Quick Start Commands

### Option 1: Local Development (Fastest for testing)

```powershell
# Step 1: Start databases (one-time setup)
.\scripts\development\start-databases.ps1

# Step 2: In 5 separate terminals, run:

# Terminal 1
cd user-service; Copy-Item .env.local .env; npm install; npm run dev

# Terminal 2
cd todo-service; Copy-Item .env.local .env; npm install; npm run dev

# Terminal 3
cd notification-service; Copy-Item .env.local .env; npm install; npm run dev

# Terminal 4
cd api-gateway; Copy-Item .env.local .env; npm install; npm run dev

# Terminal 5
cd frontend; Copy-Item .env.local .env; npm install; npm start
```

**Access**: http://localhost:3000

### Option 2: Docker Compose (Full stack)

```powershell
# Clean start
docker-compose down -v
docker-compose up --build

# Or detached mode
docker-compose up -d --build
```

**Access**: http://localhost:3000

---

## 🧪 Quick Tests

### 1. Health Checks

```powershell
curl http://localhost:8080/health
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health
curl http://localhost:3000/health
```

### 2. Register User (Browser)

1. Go to http://localhost:3000
2. Click "Register"
3. Fill in credentials
4. Submit

**Expected**: ✅ No CORS errors, successful registration

### 3. Check Browser Console (F12)

- ✅ No red CORS errors
- ✅ No 404 for favicon
- ✅ API calls succeed

---

## 🛑 Stop Services

### Local Development

```powershell
.\scripts\development\stop-local.ps1
# Or: Ctrl+C in each terminal
```

### Docker Compose

```powershell
docker-compose down
# With cleanup: docker-compose down -v
```

---

## 🔧 Troubleshooting Quick Fixes

### CORS Error?

```powershell
# 1. Check frontend .env.local
cat frontend\.env.local
# Should show: REACT_APP_API_URL=http://localhost:8080/api

# 2. Clear browser cache (Ctrl+Shift+Delete)

# 3. Restart all services
```

### Port Conflict?

```powershell
# Find what's using port 8080
netstat -ano | findstr :8080

# Stop it
Stop-Process -Id <PID> -Force
```

### Database Connection Error?

```powershell
# Start databases
.\scripts\development\start-databases.ps1

# Or check if running
docker ps | findstr postgres
```

---

## 📊 Service URLs

| Service         | URL                   | Purpose   |
| --------------- | --------------------- | --------- |
| **Frontend**    | http://localhost:3000 | UI        |
| **API Gateway** | http://localhost:8080 | API entry |
| User Service    | http://localhost:3002 | Auth      |
| Todo Service    | http://localhost:3001 | Todos     |
| Notification    | http://localhost:3003 | Notify    |

---

## ✅ Success Checklist

Before deploying to Kubernetes:

- [ ] All health checks return 200 OK
- [ ] Frontend loads without errors
- [ ] Can register a new user
- [ ] Can create todos
- [ ] No CORS errors in console
- [ ] Favicon loads (no 404)

---

## 📚 Detailed Guides

- **Complete Testing**: `LOCAL-TESTING-GUIDE.md`
- **CORS Fix Details**: `CORS-ISSUE-RESOLVED.md`
- **Setup Instructions**: `docs/SETUP.md`

---

**Remember**: Frontend only talks to API Gateway (8080), nothing else!

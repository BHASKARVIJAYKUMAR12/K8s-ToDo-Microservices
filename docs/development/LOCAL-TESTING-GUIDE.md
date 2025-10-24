# Local Development and Testing Guide

This guide will help you run and test the Todo Microservices application locally.

## 🎯 Clean Setup - Fixed All CORS Issues

All CORS issues have been resolved with this clean configuration:

- ✅ Frontend uses correct API URL: `http://localhost:8080`
- ✅ API Gateway CORS properly configured for development
- ✅ All services use consistent ports
- ✅ Environment variables properly configured
- ✅ Favicon issue fixed

---

## 📋 Prerequisites

Before you start, ensure you have:

- **Node.js** (v18 or higher)
- **npm** (v8 or higher)
- **PostgreSQL** (v15 or higher) OR Docker
- **Redis** (v7 or higher) OR Docker
- **Docker** (optional, for easy database setup)

---

## 🚀 Quick Start

### Option 1: Local Development (Recommended for Testing)

#### Step 1: Start Databases

If you have Docker:

```powershell
.\scripts\development\start-databases.ps1
```

Or manually:

- PostgreSQL on port 5432 (database: `todoapp`, user: `postgres`, password: `password`)
- Redis on port 6379

#### Step 2: Install Dependencies

```powershell
# Install dependencies for all services
cd api-gateway && npm install && cd ..
cd todo-service && npm install && cd ..
cd user-service && npm install && cd ..
cd notification-service && npm install && cd ..
cd frontend && npm install && cd ..
```

#### Step 3: Start Services Manually

**Terminal 1 - User Service:**

```powershell
cd user-service
Copy-Item .env.local .env
npm run dev
```

**Terminal 2 - Todo Service:**

```powershell
cd todo-service
Copy-Item .env.local .env
npm run dev
```

**Terminal 3 - Notification Service:**

```powershell
cd notification-service
Copy-Item .env.local .env
npm run dev
```

**Terminal 4 - API Gateway:**

```powershell
cd api-gateway
Copy-Item .env.local .env
npm run dev
```

**Terminal 5 - Frontend:**

```powershell
cd frontend
Copy-Item .env.local .env
npm start
```

#### Step 4: Access the Application

Open your browser and navigate to:

- **Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:8080

### Option 2: Docker Compose (Full Stack)

```powershell
# Build and start all services
docker-compose up --build

# Or in detached mode
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Stop and remove volumes (fresh start)
docker-compose down -v
```

Access the application:

- **Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:8080

---

## 🧪 Testing the Application

### 1. Health Checks

Test all services are running:

```powershell
# API Gateway
curl http://localhost:8080/health

# User Service
curl http://localhost:3002/health

# Todo Service
curl http://localhost:3001/health

# Notification Service
curl http://localhost:3003/health

# Frontend
curl http://localhost:3000/health
```

### 2. Register a New User

Open http://localhost:3000 and:

1. Click "Register" or navigate to registration page
2. Fill in:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `password123`
3. Click "Register"

Expected result: You should be logged in and redirected to the todos page.

### 3. Create a Todo

1. After logging in, you should see the todo list page
2. Enter a todo title: "Test my first todo"
3. Click "Add Todo"

Expected result: Todo appears in the list.

### 4. Test CORS (Browser Console)

Open browser DevTools (F12) and go to Console tab:

```javascript
// Test API call from frontend
fetch("http://localhost:8080/api/auth/register", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    username: "testuser2",
    email: "test2@example.com",
    password: "password123",
  }),
})
  .then((r) => r.json())
  .then(console.log)
  .catch(console.error);
```

Expected result: No CORS errors, successful response or user exists error.

---

## 🔧 Troubleshooting

### CORS Errors

If you still see CORS errors:

1. **Clear browser cache**: Ctrl + Shift + Delete
2. **Check API URL** in `frontend/.env.local`: Should be `http://localhost:8080/api`
3. **Restart all services** to pick up new environment variables
4. **Check browser console** for the exact error message

### Port Conflicts

If ports are already in use:

```powershell
# Check what's using a port
netstat -ano | findstr :8080

# Stop the process (replace PID with actual process ID)
Stop-Process -Id <PID> -Force
```

Or use the stop script:

```powershell
.\scripts\development\stop-local.ps1
```

### Database Connection Issues

1. Ensure PostgreSQL is running:

   ```powershell
   # If using Docker
   docker ps | findstr postgres

   # If installed locally
   Get-Service postgresql*
   ```

2. Test database connection:

   ```powershell
   # Using psql
   psql -h localhost -U postgres -d todoapp -c "\dt"
   ```

3. Check environment variables in `.env.local` files

### Services Won't Start

1. **Install dependencies**:

   ```powershell
   # For each service
   npm install
   ```

2. **Build TypeScript**:

   ```powershell
   # For backend services
   npm run build
   ```

3. **Check logs** for specific errors

---

## 📊 Service URLs Reference

| Service              | URL                   | Purpose         |
| -------------------- | --------------------- | --------------- |
| Frontend             | http://localhost:3000 | React UI        |
| API Gateway          | http://localhost:8080 | API entry point |
| User Service         | http://localhost:3002 | Authentication  |
| Todo Service         | http://localhost:3001 | Todo CRUD       |
| Notification Service | http://localhost:3003 | Notifications   |
| PostgreSQL           | localhost:5432        | Database        |
| Redis                | localhost:6379        | Cache/Queue     |

---

## 🎯 Port Configuration Summary

**Clean and Consistent Ports:**

- `3000` - Frontend (React dev server or Nginx)
- `8080` - API Gateway (Main entry point)
- `3001` - Todo Service
- `3002` - User Service
- `3003` - Notification Service
- `5432` - PostgreSQL
- `6379` - Redis

**No more confusion!** All services use these ports consistently across:

- Local development
- Docker Compose
- Kubernetes deployments

---

## ✅ Next Steps

After successfully testing locally:

1. **Build Docker images**:

   ```powershell
   docker-compose build
   ```

2. **Deploy to Kubernetes**:

   ```powershell
   .\scripts\development\deploy-local-k8s.ps1
   ```

3. **Test Kubernetes deployment**:
   ```powershell
   .\scripts\development\test-local-deployment.ps1
   ```

---

## 📝 Environment Variables

All services use `.env.local` files for local development. These files are automatically used when you start services.

**Frontend** (`.env.local`):

```
REACT_APP_API_URL=http://localhost:8080/api
```

**API Gateway** (`.env.local`):

```
PORT=8080
NODE_ENV=development
TODO_SERVICE_URL=http://localhost:3001
USER_SERVICE_URL=http://localhost:3002
NOTIFICATION_SERVICE_URL=http://localhost:3003
ALLOWED_ORIGINS=http://localhost:3000
```

See individual service directories for complete `.env.local` files.

---

## 🆘 Getting Help

If you encounter issues:

1. Check this guide's Troubleshooting section
2. Review service logs for error messages
3. Ensure all prerequisites are installed
4. Verify environment variables are correct
5. Try a fresh start: stop all services, clear caches, restart

---

## 🎉 Success Criteria

You'll know everything is working when:

✅ All health checks return 200 OK  
✅ Frontend loads without errors  
✅ No CORS errors in browser console  
✅ Can register a new user  
✅ Can create, view, update, and delete todos  
✅ Todos persist after page refresh  
✅ Authentication works (login/logout)

---

**Last Updated**: 2025-10-21  
**Version**: 2.0 - Clean Configuration

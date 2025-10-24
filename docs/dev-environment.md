# 🚀 Development Environment Setup

## 🔄 **Local Development vs Docker Development**

### **When to Use Each Approach:**

#### 🏠 **Local Development (Recommended for Development)**

- ✅ **Instant feedback**: Changes appear immediately
- ✅ **Hot reload**: React auto-refreshes, backend restarts automatically
- ✅ **Better debugging**: Direct access to logs and debugger
- ✅ **Faster iteration**: No build time for containers
- ❌ **Dependency management**: Need Node.js, npm installed locally
- ❌ **Environment differences**: Might work locally but fail in production

#### 🐳 **Docker Development (Recommended for Testing/Production)**

- ✅ **Consistent environment**: Same as production
- ✅ **Easy deployment**: Containers work everywhere
- ✅ **Isolation**: Services don't interfere with each other
- ✅ **Easy scaling**: Can run multiple instances
- ❌ **Slower development**: Need to rebuild for changes
- ❌ **Resource intensive**: Docker uses more RAM/CPU

## 🛠️ **Local Development Setup**

### **Prerequisites**

```powershell
# Install Node.js 18+
# Install npm
# Docker for databases only
```

### **1. Start Databases (Docker)**

```powershell
# Only run databases in Docker (easier than local setup)
docker-compose up -d postgres redis

# Check they're running
docker ps
```

### **2. Start Backend Services (Local)**

**Terminal 1 - API Gateway:**

```powershell
cd api-gateway
npm install
npm run dev    # Runs on http://localhost:8080
```

**Terminal 2 - User Service:**

```powershell
cd user-service
npm install
npm run dev    # Runs on http://localhost:3002
```

**Terminal 3 - Todo Service:**

```powershell
cd todo-service
npm install
npm run dev    # Runs on http://localhost:3001
```

**Terminal 4 - Notification Service:**

```powershell
cd notification-service
npm install
npm run dev    # Runs on http://localhost:3003
```

**Terminal 5 - Frontend:**

```powershell
cd frontend
npm install
npm start      # Runs on http://localhost:3000
```

### **3. Environment Variables**

Create `.env` files for local development:

**api-gateway/.env.local**

```env
PORT=8080
TODO_SERVICE_URL=http://localhost:3001
USER_SERVICE_URL=http://localhost:3002
NOTIFICATION_SERVICE_URL=http://localhost:3003
FRONTEND_URL=http://localhost:3000
```

**user-service/.env.local**

```env
PORT=3002
DB_HOST=localhost
DB_PORT=5432
DB_NAME=todo_db
DB_USER=todo_user
DB_PASSWORD=password
JWT_SECRET=your-secret-key
```

**todo-service/.env.local**

```env
PORT=3001
DB_HOST=localhost
DB_PORT=5432
DB_NAME=todo_db
DB_USER=todo_user
DB_PASSWORD=password
JWT_SECRET=your-secret-key
```

## 🔄 **Development Workflow**

### **For Frontend Changes:**

1. Edit React files in `frontend/src/`
2. ✅ **Instant reload** - changes appear immediately
3. No rebuild needed

### **For Backend Changes:**

1. Edit TypeScript files in `service/src/`
2. ✅ **Auto restart** - nodemon detects changes
3. No rebuild needed

### **For Production Testing:**

1. Run `docker-compose up --build -d`
2. Test production-like environment
3. Deploy with confidence

## 📊 **Performance Comparison**

| Task             | Local Development | Docker Development |
| ---------------- | ----------------- | ------------------ |
| Initial Setup    | 2 minutes         | 5 minutes          |
| Code Change      | Instant           | 2-5 minutes        |
| Debug Issue      | Easy              | Moderate           |
| Production Match | 90%               | 100%               |
| Resource Usage   | Low               | High               |

## 🎯 **Best Practice: Hybrid Approach**

**Daily Development:**

- Use local development for fast iteration
- Run databases in Docker for consistency
- Hot reload for instant feedback

**Before Deployment:**

- Test with Docker containers
- Run full integration tests
- Verify production environment works

## 🚨 **Common Issues & Solutions**

### **Port Conflicts**

```powershell
# Check what's using a port
netstat -an | findstr :3000

# Kill process on port
npx kill-port 3000
```

### **Database Connection Issues**

```powershell
# Ensure Docker databases are running
docker ps | findstr postgres
docker ps | findstr redis

# Check database logs
docker logs kubernetes-demo-folder-postgres-1
```

### **Dependencies Issues**

```powershell
# Clean install
rm -rf node_modules package-lock.json
npm install
```

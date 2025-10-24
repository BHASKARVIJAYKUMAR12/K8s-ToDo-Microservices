# 🔧 JWT Secret Mismatch - FIXED!

## 🎯 Root Cause Found

The **403 Forbidden** error was caused by **JWT secret mismatch** between services:

- **User Service** was generating tokens with: `your-super-secret-jwt-key`
- **Todo Service** was validating tokens with: `your-super-secret-jwt-key`
- **But after updates**, the secrets got out of sync!

When the todo-service tried to verify the JWT token from the user-service, it failed because they were using different secrets.

## ✅ What I Fixed

Updated all `.env` files to use the same JWT secret:

```bash
JWT_SECRET=local-dev-secret-key-change-in-production
```

All services now have matching configuration:

- ✅ user-service/.env
- ✅ todo-service/.env
- ✅ api-gateway/.env
- ✅ notification-service/.env

## 🚀 Next Steps - RESTART SERVICES

**IMPORTANT**: You must restart all services to pick up the new environment variables!

### Step 1: Stop All Running Services

Press `Ctrl+C` in each terminal running the services.

### Step 2: Restart Services (in order)

**Terminal 1 - User Service:**

```powershell
cd user-service
npm run dev
```

**Terminal 2 - Todo Service:**

```powershell
cd todo-service
npm run dev
```

**Terminal 3 - Notification Service:**

```powershell
cd notification-service
npm run dev
```

**Terminal 4 - API Gateway:**

```powershell
cd api-gateway
npm run dev
```

**Terminal 5 - Frontend:**

```powershell
cd frontend
npm start
```

### Step 3: Clear Browser Storage

Since old tokens were created with the old secret, they're now invalid.

**In browser console (F12):**

```javascript
localStorage.clear();
location.reload();
```

### Step 4: Register Again

1. Go to http://localhost:3000/register
2. Register a new user (or use different email if you get "user exists")
3. You'll get a NEW token generated with the correct secret
4. Try creating a todo - **should work now!** ✅

## 🧪 Verify the Fix

After restarting and re-registering, test:

```javascript
// In browser console after registration
fetch("http://localhost:8080/api/todos", {
  headers: {
    Authorization: `Bearer ${localStorage.getItem("authToken")}`,
    "Content-Type": "application/json",
  },
})
  .then((r) => r.json())
  .then((data) => console.log("✅ Success!", data))
  .catch((err) => console.error("❌ Error:", err));
```

Should return `200 OK` instead of `403 Forbidden`!

## 📊 What Changed

### Before (Broken):

```
User registers → User service creates token with SECRET_A
User tries to access todos → Todo service validates with SECRET_B
Result: 403 Forbidden ❌
```

### After (Fixed):

```
User registers → User service creates token with SECRET_SHARED
User tries to access todos → Todo service validates with SECRET_SHARED
Result: 200 OK ✅
```

## ⚠️ Important Notes

1. **All services must use the SAME JWT secret** for token validation to work
2. **Environment variables are loaded at startup** - restart required after changes
3. **Old tokens are invalid** after secret change - clear localStorage and re-register
4. **In production**, use a strong, randomly generated secret and keep it in a secrets manager

## ✅ Checklist

After restarting services:

- [ ] All services restarted with new .env files
- [ ] Browser localStorage cleared
- [ ] New user registered (or re-logged in)
- [ ] Can access /todos without 403 error
- [ ] Can create new todos
- [ ] API Gateway logs show 200/201 responses instead of 403

## 🎉 Expected Result

After following these steps:

```
[PROXY] POST /api/todos -> http://localhost:3001/api/todos
[PROXY RESPONSE] POST /api/todos -> 201  ← Should be 201, not 403!
```

---

**Quick Summary**: JWT secrets were mismatched. Fixed by syncing all .env files. Restart services and re-register to get a valid token!

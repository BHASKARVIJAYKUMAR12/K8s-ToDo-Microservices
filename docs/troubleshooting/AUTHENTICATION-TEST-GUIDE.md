# 🔐 Quick Authentication Testing Guide

## The Issue

You're seeing **403 Forbidden** when accessing `/api/todos` because:

- The todos endpoint requires authentication (JWT token)
- You need to login/register first to get a token

## ✅ Quick Fix - Step by Step

### Step 1: Start All Services

Make sure all services are running:

```powershell
# Check if services are running
netstat -ano | findstr ":3000 :8080 :3001 :3002"
```

### Step 2: Open Frontend

Go to: **http://localhost:3000**

You should be automatically redirected to `/login`

### Step 3: Register a New User

1. Click "Register" (or navigate to http://localhost:3000/register)
2. Fill in the form:
   ```
   Username: testuser
   Email: test@example.com
   Password: password123
   ```
3. Click "Register" button
4. **Watch the browser console (F12)** for any errors

### Step 4: Check for Success

After successful registration:

- ✅ You should be redirected to `/todos`
- ✅ The todos page should load
- ✅ You can now create todos

### Step 5: Verify Token in Console

Open browser console (F12) and run:

```javascript
// Check if token was saved
console.log("Token exists:", !!localStorage.getItem("authToken"));
console.log("User:", localStorage.getItem("user"));
```

Should show: `Token exists: true`

---

## 🧪 Test Authentication Flow

### Option 1: Using Browser Console

Open http://localhost:3000, then press F12 and paste:

```javascript
// Test 1: Register a new user
async function testRegister() {
  try {
    const response = await fetch("http://localhost:8080/api/auth/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: "testuser" + Date.now(),
        email: `test${Date.now()}@example.com`,
        password: "password123",
      }),
    });

    const data = await response.json();
    console.log("Register response:", data);

    if (data.token) {
      localStorage.setItem("authToken", data.token);
      localStorage.setItem("user", JSON.stringify(data.user));
      console.log("✅ Token saved! You can now access todos.");

      // Test getting todos
      return testGetTodos();
    }
  } catch (err) {
    console.error("❌ Register error:", err);
  }
}

// Test 2: Get todos with token
async function testGetTodos() {
  const token = localStorage.getItem("authToken");

  if (!token) {
    console.error("❌ No token! Please register first.");
    return;
  }

  try {
    const response = await fetch("http://localhost:8080/api/todos", {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    });

    console.log("Status:", response.status);
    const data = await response.json();
    console.log("Todos response:", data);

    if (response.status === 200) {
      console.log("✅ Success! Todos retrieved.");
    } else if (response.status === 403) {
      console.error("❌ 403 Forbidden - Token is invalid or expired");
    }
  } catch (err) {
    console.error("❌ Get todos error:", err);
  }
}

// Test 3: Create a todo
async function testCreateTodo() {
  const token = localStorage.getItem("authToken");

  if (!token) {
    console.error("❌ No token! Please register first.");
    return;
  }

  try {
    const response = await fetch("http://localhost:8080/api/todos", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        title: "Test Todo",
        description: "Testing authentication",
      }),
    });

    const data = await response.json();
    console.log("Create todo response:", data);

    if (response.status === 201) {
      console.log("✅ Todo created successfully!");
    }
  } catch (err) {
    console.error("❌ Create todo error:", err);
  }
}

// Run the test
console.log("🧪 Running authentication test...");
testRegister();
```

### Option 2: Using curl (PowerShell)

```powershell
# Test 1: Register
$registerResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/auth/register" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"username":"testuser","email":"test@example.com","password":"password123"}' `
  | ConvertFrom-Json

$token = $registerResponse.token
Write-Host "Token: $token"

# Test 2: Get todos with token
Invoke-WebRequest -Uri "http://localhost:8080/api/todos" `
  -Headers @{"Authorization"="Bearer $token"}
```

---

## 🔍 Debugging Checklist

### Check 1: Services Running?

```powershell
# All should return results
curl http://localhost:8080/health
curl http://localhost:3002/health  # User service
curl http://localhost:3001/health  # Todo service
```

### Check 2: Can Register?

```powershell
# Should return status 201 with token
curl -X POST http://localhost:8080/api/auth/register `
  -H "Content-Type: application/json" `
  -d '{"username":"testuser2","email":"test2@example.com","password":"password123"}'
```

### Check 3: Token in Browser?

Open console (F12):

```javascript
localStorage.getItem("authToken"); // Should return a long string
```

### Check 4: Network Tab

1. Open DevTools (F12)
2. Go to Network tab
3. Try to load todos
4. Click on the request
5. Check "Request Headers" section
6. Should see: `Authorization: Bearer eyJ...`

---

## 🚨 Common Issues

### Issue 1: "No token found"

**Solution**: You're not logged in. Complete the registration/login flow.

### Issue 2: "403 Forbidden"

**Causes**:

- Token is missing
- Token is invalid
- Token is expired (24h expiry)

**Solution**:

```javascript
// Clear and login again
localStorage.clear();
// Then go to /register
```

### Issue 3: "Token is there but still 403"

**Possible causes**:

- Token format is wrong
- JWT secret mismatch between services
- Token was generated with different secret

**Solution**:

1. Check user-service logs for JWT errors
2. Verify JWT_SECRET is same in all .env.local files
3. Re-register to get a fresh token

### Issue 4: "CORS errors"

If you see CORS errors instead of 403:

- Go back to the CORS fixes we implemented earlier
- Clear browser cache
- Restart API Gateway

---

## 📊 Expected Flow

```
User visits localhost:3000
    ↓
Redirected to /login (not authenticated)
    ↓
User clicks "Register"
    ↓
Fills form and submits
    ↓
POST /api/auth/register
    ↓
Backend returns: { token: "...", user: {...} }
    ↓
Token saved to localStorage
    ↓
User redirected to /todos
    ↓
TodoList component mounts
    ↓
Calls getTodos() with token in header
    ↓
Backend validates token
    ↓
Returns todos for that user
    ↓
Success! ✅
```

---

## ✅ Success Indicators

You know it's working when:

1. **Registration succeeds** (no errors in console)
2. **Token is saved** (`localStorage.getItem('authToken')` returns a value)
3. **Redirected to /todos** automatically
4. **Todos page loads** without 403 errors
5. **Network tab shows** `Authorization: Bearer ...` header
6. **Can create todos** successfully

---

## 🎯 Quick Test Script

Save this as `test-auth.ps1`:

```powershell
Write-Host "Testing Authentication Flow..." -ForegroundColor Cyan

# Test registration
Write-Host "`n1. Testing Registration..." -ForegroundColor Yellow
$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$body = @{
    username = "testuser$timestamp"
    email = "test$timestamp@example.com"
    password = "password123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/register" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body

    $token = $response.token
    Write-Host "✅ Registration successful!" -ForegroundColor Green
    Write-Host "Token: $($token.Substring(0, 20))..." -ForegroundColor Gray

    # Test getting todos
    Write-Host "`n2. Testing Get Todos..." -ForegroundColor Yellow
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }

    $todosResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/todos" `
        -Headers $headers

    Write-Host "✅ Todos retrieved successfully!" -ForegroundColor Green
    Write-Host "Todos count: $($todosResponse.Count)" -ForegroundColor Gray

    # Test creating a todo
    Write-Host "`n3. Testing Create Todo..." -ForegroundColor Yellow
    $todoBody = @{
        title = "Test Todo"
        description = "Created via test script"
    } | ConvertTo-Json

    $newTodo = Invoke-RestMethod -Uri "http://localhost:8080/api/todos" `
        -Method POST `
        -Headers $headers `
        -Body $todoBody

    Write-Host "✅ Todo created successfully!" -ForegroundColor Green
    Write-Host "Todo ID: $($newTodo.id)" -ForegroundColor Gray

    Write-Host "`n✅ All tests passed! Authentication is working correctly." -ForegroundColor Green

} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
```

Run it:

```powershell
.\test-auth.ps1
```

---

## 💡 Remember

**The 403 error is EXPECTED if you're not logged in!**

This is correct behavior - the todos API is protected and requires authentication. Simply complete the login/registration flow in the browser and you'll be able to access todos.

---

**Next Step**: Go to http://localhost:3000 and click "Register"! 🚀

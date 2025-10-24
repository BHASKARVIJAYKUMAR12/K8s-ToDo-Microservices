# 403 Forbidden Error - Authentication Issue

## 🔍 Problem

You're seeing:

```
GET http://localhost:8080/api/todos 403 (Forbidden)
POST http://localhost:8080/api/todos 403 (Forbidden)
```

## 🎯 Root Cause

The `/api/todos` endpoint requires authentication (JWT token), but either:

1. You're not logged in
2. The token isn't being sent with requests
3. The token is invalid or expired

## ✅ Solution Steps

### Step 1: Check if You're Logged In

Open browser console (F12) and run:

```javascript
// Check if token exists
console.log("Token:", localStorage.getItem("authToken"));
console.log("User:", localStorage.getItem("user"));
```

**If null**: You need to login/register first!

### Step 2: Test Registration

1. Go to http://localhost:3000/register
2. Register a new user:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `password123`
3. You should be redirected to `/todos`

### Step 3: Verify Token is Sent

In browser console (F12), check Network tab:

1. Go to Network tab
2. Try to load todos (refresh the page)
3. Click on the `todos` request
4. Check **Request Headers**
5. Look for: `Authorization: Bearer <your-token>`

**If missing**: Token isn't being added to requests!

### Step 4: Manual Test

In browser console (F12):

```javascript
// Test if token is being sent
fetch("http://localhost:8080/api/todos", {
  headers: {
    Authorization: `Bearer ${localStorage.getItem("authToken")}`,
    "Content-Type": "application/json",
  },
})
  .then((r) => r.json())
  .then((data) => console.log("Success:", data))
  .catch((err) => console.error("Error:", err));
```

## 🔧 Quick Fixes

### Fix 1: Login First

The easiest solution:

1. Go to http://localhost:3000
2. Click "Register" (or "Login" if you already have an account)
3. Complete registration/login
4. You should automatically be redirected to todos page

### Fix 2: Clear and Re-login

If token is corrupted:

```javascript
// In browser console
localStorage.clear();
```

Then register/login again.

### Fix 3: Check API Gateway Logs

In your API Gateway terminal, you should see:

```
[PROXY] GET /api/todos -> http://localhost:3001/api/todos
```

If you see CORS errors, that's the CORS issue we fixed earlier.

## 🧪 Testing Script

Create this test file to verify authentication:

**test-auth.html** (open in browser):

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Auth Test</title>
  </head>
  <body>
    <h1>Authentication Test</h1>
    <button onclick="testRegister()">1. Test Register</button>
    <button onclick="testLogin()">2. Test Login</button>
    <button onclick="testTodos()">3. Test Get Todos</button>
    <button onclick="checkToken()">Check Token</button>
    <pre id="output"></pre>

    <script>
      const API = "http://localhost:8080/api";
      const log = (msg) => {
        document.getElementById("output").textContent += msg + "\n";
        console.log(msg);
      };

      async function testRegister() {
        try {
          const response = await fetch(`${API}/auth/register`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              username: "testuser" + Date.now(),
              email: `test${Date.now()}@example.com`,
              password: "password123",
            }),
          });
          const data = await response.json();
          if (data.token) {
            localStorage.setItem("authToken", data.token);
            log("✅ Registration successful! Token saved.");
          } else {
            log("❌ Registration failed: " + JSON.stringify(data));
          }
        } catch (err) {
          log("❌ Error: " + err.message);
        }
      }

      async function testLogin() {
        try {
          const response = await fetch(`${API}/auth/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              username: "testuser",
              password: "password123",
            }),
          });
          const data = await response.json();
          if (data.token) {
            localStorage.setItem("authToken", data.token);
            log("✅ Login successful! Token saved.");
          } else {
            log("❌ Login failed: " + JSON.stringify(data));
          }
        } catch (err) {
          log("❌ Error: " + err.message);
        }
      }

      async function testTodos() {
        const token = localStorage.getItem("authToken");
        if (!token) {
          log("❌ No token found! Please login first.");
          return;
        }

        try {
          const response = await fetch(`${API}/todos`, {
            headers: {
              Authorization: `Bearer ${token}`,
              "Content-Type": "application/json",
            },
          });

          log(`Response status: ${response.status}`);

          const data = await response.json();

          if (response.ok) {
            log("✅ Todos retrieved successfully: " + JSON.stringify(data));
          } else {
            log("❌ Failed: " + JSON.stringify(data));
          }
        } catch (err) {
          log("❌ Error: " + err.message);
        }
      }

      function checkToken() {
        const token = localStorage.getItem("authToken");
        if (token) {
          log("✅ Token exists: " + token.substring(0, 20) + "...");

          // Decode JWT to check expiry
          try {
            const payload = JSON.parse(atob(token.split(".")[1]));
            log("Token payload: " + JSON.stringify(payload, null, 2));
            log("Expires: " + new Date(payload.exp * 1000).toLocaleString());
          } catch (err) {
            log("Could not decode token");
          }
        } else {
          log("❌ No token found in localStorage");
        }
      }
    </script>
  </body>
</html>
```

Save this file and open it in your browser to test authentication flow.

## 📝 Summary

The 403 error means you need to:

1. **Register or Login first** at http://localhost:3000/register
2. **The token will be saved** in localStorage
3. **Then you can access** the todos page

The todos API is protected and requires authentication - this is working as designed!

## ✅ Expected Flow

1. User visits http://localhost:3000
2. Gets redirected to `/login`
3. User clicks "Register" → fills form → submits
4. Backend returns token
5. Token saved to localStorage
6. User redirected to `/todos`
7. TodoList component loads
8. Axios automatically adds token to requests
9. Todos are fetched successfully

If you're seeing 403, you're likely skipping steps 3-5!

## 🔍 Debug Commands

```javascript
// In browser console

// 1. Check authentication state
console.log("Authenticated:", !!localStorage.getItem("authToken"));

// 2. Clear everything and start fresh
localStorage.clear();

// 3. Check if token is in requests
// Open Network tab, filter for "todos", check Request Headers
```

---

**Next Step**: Go to http://localhost:3000 and complete the registration/login flow!

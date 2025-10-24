# 🎯 Final Testing Instructions

## ✅ Services are NOW Running

Your microservices application is deployed and running with CORS properly configured!

### 🌐 Access URLs:

- **Frontend UI**: http://localhost:3000
- **API Gateway**: http://localhost:8081

## 📋 Test Registration (CORS Fix Applied)

### Step 1: Open the Application

```
http://localhost:3000
```

### Step 2: Clear Browser Cache

**CRITICAL:** You MUST clear your browser cache or the old JavaScript will be used!

- Press **Ctrl + Shift + R** (hard refresh) 2-3 times
- Or press **Ctrl + F5**
- Or open DevTools (F12) → Right-click refresh → "Empty Cache and Hard Reload"

### Step 3: Open Browser DevTools

- Press **F12**
- Go to **Network** tab
- Keep it open during testing

### Step 4: Register a New User

Fill in the registration form:

- **Username**: `testuser`
- **Email**: `test@example.com`
- **Password**: `password123`

Click **Register**

### Step 5: Verify Success

**In the Network Tab, you should see:**

```
✅ Request to: http://localhost:8081/api/auth/register
✅ Status: 201 Created
✅ Response Headers include:
   - Access-Control-Allow-Origin: http://localhost:3000
   - Access-Control-Allow-Credentials: true
✅ Response Body contains:
   - token: "eyJhbGciOiJIUzI..."
   - user: { id, username, email }
```

**In the Console Tab:**

```
✅ NO CORS errors
✅ NO "blocked by CORS policy" messages
```

## 🧪 Additional Tests

### Test Login

After successful registration:

1. Go to Login page
2. Enter the same username and password
3. Should see: Status 200, token returned

### Test Todos

After logging in:

1. Create a new todo
2. Mark it as complete
3. Delete it
4. All should work without CORS errors

## 🔍 Troubleshooting

### Still seeing CORS errors?

1. **Hard refresh again**: Ctrl + Shift + R (do it 3-4 times!)
2. **Check port-forwards are running**:

   ```powershell
   Get-Process kubectl
   ```

   Should see 2 kubectl processes

3. **Restart port-forwards if needed**:

   ```powershell
   Get-Process kubectl | Stop-Process -Force

   Start-Process powershell -WindowStyle Minimized -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n todo-app svc/api-gateway-service 8081:8080"

   Start-Process powershell -WindowStyle Minimized -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n todo-app svc/frontend-service 3000:80"
   ```

### Wrong port in error message?

If you see `localhost:8080` in errors (not 8081), the browser is still using cached code.

- Clear browser cache completely
- Close all browser tabs
- Reopen browser
- Go to `http://localhost:3000`

### API Gateway not responding?

```powershell
# Test health endpoint
curl.exe http://localhost:8081/health

# Should return: {"status":"healthy",...}
```

## 📊 Check Pod Status

```powershell
kubectl get pods -n todo-app
```

All pods should show `Running` with `1/1 READY`:

```
NAME                                   READY   STATUS
api-gateway-xxxxxxxxx-xxxxx            1/1     Running
frontend-xxxxxxxxx-xxxxx               1/1     Running
user-service-xxxxxxxxx-xxxxx           1/1     Running
todo-service-xxxxxxxxx-xxxxx           1/1     Running
notification-service-xxxxxxxxx-xxxxx   1/1     Running
postgres-xxxxxxxxx-xxxxx               1/1     Running
redis-xxxxxxxxx-xxxxx                  1/1     Running
```

## 🎉 Success Criteria

- ✅ Can register new users
- ✅ Can login
- ✅ Can create todos
- ✅ No CORS errors in console
- ✅ All API calls return proper responses

## 🚀 Next Steps

After successful local testing:

1. **Commit your changes** to Git
2. **Push to your repository**
3. **Deploy to GKE** using production scripts
4. **Set up Ingress** for external access
5. **Configure HTTPS** with cert-manager
6. **Set up monitoring** with Prometheus/Grafana

## 📝 Important Notes

- Port 8080 conflicts with Apache on Windows → Using 8081
- Frontend uses `http://localhost:8081/api` as API base URL
- CORS allows `localhost:3000` and other origins
- `withCredentials: true` enables authentication cookies
- Docker images use `:local` tag for local development

---

**Your Todo Microservices App is Ready for Testing!** 🎊

# 🎨 Kubernetes Dashboard - Quick Access Guide

## 🌐 **Dashboard is Now Open!**

The Kubernetes Dashboard UI should now be open in VS Code's Simple Browser.

---

## 🔑 **Login Instructions**

### Step 1: Select "Token" Authentication

On the login page, you'll see two options:

- **Kubeconfig**
- **Token** ← Select this one

### Step 2: Copy and Paste Your Access Token

**Your Access Token (Valid for 24 hours):**

```
eyJhbGciOiJSUzI1NiIsImtpZCI6IkVRdm11cV85TjF1WkJxZks4OEdiZFJhUkp4MEpNM0wySFZiLWFHZTlRMUkifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzYwNzkzMzc2LCJpYXQiOjE3NjA3MDY5NzYsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiOWZjNjY5Y2MtYWU2OC00MzExLTgzNWItNzRkYzEwMzQ3YTQ1Iiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJkYXNoYm9hcmQtYWRtaW4iLCJ1aWQiOiI3ZGYzOWJhYS02OGNmLTQ3M2MtOTZiZC1kNWMzZTY3YTlmMzcifX0sIm5iZiI6MTc2MDcwNjk3Niwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmVybmV0ZXMtZGFzaGJvYXJkOmRhc2hib2FyZC1hZG1pbiJ9.dx_pcg5lDjRLNMa9NYnDNnucLZdG8C1a779gAeoQtkNCQjlH0oXHcL1UOAQTF2peHEA268JdOmy2qpEXnIryUq0c-vnSnyvlIdsv8Z-BC2krnhKKNE7rDDxh6HShqPmTkeD5R8UNfQP87yntckQBZFXeaDJZ4pg45TmZm1BPfMyTWtLmvG7N1BqyDfuxxXAKBuZo8zWNNaJ-604zWt4Sqnu_pzjGlC485-6KPEJKUeThe7itwiXfs8xPa6UNPoxMKqsjLAfEJklP_qKeI1NrLUPNfdzs7MUSgjwmbqJmMioBJokol_KoIsVj3HA2C8OmLB1_FNGRR5nmWHP-NsigBg
```

### Step 3: Click "Sign In"

---

## 📊 **Viewing Your Todo App in Dashboard**

### 1. **Select Namespace**

Once logged in:

1. Look at the top navigation bar
2. Find the **namespace dropdown** (usually says "default")
3. Click it and select **"todo-app"**

### 2. **Navigate to Pods**

In the left sidebar:

1. Click **"Workloads"**
2. Click **"Pods"**

You'll now see all your running pods with:

- ✅ Status (Running, Pending, etc.)
- ✅ Ready state (1/1)
- ✅ Restart count
- ✅ CPU and Memory usage
- ✅ Age
- ✅ IP addresses

### 3. **View Pod Details**

Click on any pod name (e.g., `api-gateway-xxx`) to see:

- **Overview**: Status, labels, created time
- **Logs**: Real-time container logs
- **Events**: Pod lifecycle events
- **YAML**: Full pod configuration
- **Exec**: Execute commands in the container

### 4. **Other Useful Views**

**Deployments:**

- Sidebar → Workloads → Deployments
- See your 7 deployments (api-gateway, frontend, etc.)
- View replicas, update strategy

**Services:**

- Sidebar → Service → Services
- See your services and their endpoints
- Check ClusterIP, NodePort, LoadBalancer

**Config and Storage:**

- ConfigMaps: View app-config
- Secrets: View app-secrets (values are base64 encoded)

**Cluster:**

- Nodes: See your Docker Desktop node
- Namespaces: See all namespaces

---

## 🎯 **Dashboard Features**

### **What You Can Do in Dashboard:**

#### ✅ **View Resources**

- Pods, Deployments, Services, ConfigMaps, Secrets
- Real-time status updates
- Resource usage graphs

#### ✅ **View Logs**

- Click any pod → Click "Logs" tab
- Real-time log streaming
- Filter and search logs

#### ✅ **Execute Commands**

- Click any pod → Click "Exec" tab
- Opens shell inside container
- Run commands directly

#### ✅ **Edit Resources**

- Click "Edit" on any resource
- Modify YAML configuration
- Apply changes instantly

#### ✅ **Scale Deployments**

- Go to Deployments
- Click the three dots (⋮) on a deployment
- Select "Scale"
- Increase/decrease replicas

#### ✅ **Delete Resources**

- Select any resource
- Click delete button
- Confirm deletion

#### ✅ **Monitor Health**

- See pod status at a glance
- View resource consumption
- Track restart counts

---

## 🌍 **Alternative Access Methods**

### **Method 1: VS Code Simple Browser (Current)**

Already open in VS Code!

### **Method 2: External Browser**

Open your regular browser (Chrome, Edge, etc.) and go to:

```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

Use the same token to login.

### **Method 3: Direct NodePort Access**

```powershell
# Get NodePort
kubectl get service kubernetes-dashboard -n kubernetes-dashboard

# Access directly (if NodePort is available)
# https://localhost:<NodePort>
```

---

## 🔧 **Troubleshooting**

### **Dashboard Not Loading?**

#### 1. Check if proxy is running:

```powershell
Get-Process kubectl | Where-Object {$_.ProcessName -eq "kubectl"}
```

#### 2. Restart proxy:

```powershell
# Kill existing proxy
Get-Process kubectl | Where-Object {$_.ProcessName -eq "kubectl"} | Stop-Process -Force

# Start new proxy
kubectl proxy
```

#### 3. Check dashboard pods:

```powershell
kubectl get pods -n kubernetes-dashboard
```

Should show:

```
NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-xxx                1/1     Running   0          Xh
kubernetes-dashboard-xxx                     1/1     Running   0          Xh
```

### **Token Expired?**

Generate a new token:

```powershell
kubectl create token dashboard-admin -n kubernetes-dashboard --duration=24h
```

### **Can't See "todo-app" Namespace?**

Make sure you're logged in with the token. The token has cluster-admin permissions, so you should see all namespaces.

---

## 📋 **Quick Commands**

### **Start Dashboard Access**

```powershell
# 1. Start proxy
kubectl proxy

# 2. Get token
kubectl create token dashboard-admin -n kubernetes-dashboard --duration=24h

# 3. Open browser to:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### **Stop Dashboard**

```powershell
# Stop proxy
Get-Process kubectl | Where-Object {$_.ProcessName -eq "kubectl"} | Stop-Process -Force
```

### **Check Dashboard Status**

```powershell
kubectl get all -n kubernetes-dashboard
```

---

## 🎨 **Dashboard UI Tips**

### **Keyboard Shortcuts**

- **Ctrl+K**: Quick search
- **ESC**: Close dialogs
- **Tab**: Navigate between sections

### **Useful Filters**

- Filter by **Status**: Click status badges
- Search by **Name**: Use search box
- Filter by **Labels**: Click on labels

### **Viewing Logs**

1. Click on a pod
2. Go to "Logs" tab
3. Options:
   - **Auto-refresh**: Logs update automatically
   - **Timestamp**: Show/hide timestamps
   - **Download**: Download logs as file
   - **Previous**: View logs from previous instance

### **Executing Commands**

1. Click on a pod
2. Go to "Exec" tab
3. Terminal opens in container
4. Run any command (e.g., `ls`, `ps`, `env`)

---

## 🚀 **What to Check in Dashboard**

### **For Your Todo App:**

#### 1. **Pods Status** (Workloads → Pods)

All should be:

- Status: **Running** ✅
- Ready: **1/1** ✅
- Restarts: Low number ✅

#### 2. **Deployments** (Workloads → Deployments)

All should show:

- Desired: 1
- Current: 1
- Ready: 1
- Available: 1

#### 3. **Services** (Service → Services)

Check:

- **api-gateway-service**: LoadBalancer (8080)
- **frontend-service**: LoadBalancer (80)
- **user-service**: ClusterIP (3002)
- **todo-service**: ClusterIP (3001)
- **notification-service**: ClusterIP (3003)
- **postgres-service**: ClusterIP (5432)
- **redis-service**: ClusterIP (6379)

#### 4. **ConfigMaps** (Config and Storage → Config Maps)

Should see:

- **app-config**: Contains environment variables

#### 5. **Secrets** (Config and Storage → Secrets)

Should see:

- **app-secrets**: Contains database credentials, JWT secret, etc.

---

## 📊 **Dashboard vs kubectl**

| Feature               | Dashboard            | kubectl         |
| --------------------- | -------------------- | --------------- |
| **Visual UI**         | ✅ Yes               | ❌ No           |
| **Real-time Updates** | ✅ Yes               | ⚠️ Use --watch  |
| **Logs Viewing**      | ✅ Easy              | ✅ Yes          |
| **Editing YAML**      | ✅ Built-in editor   | ⚠️ Need editor  |
| **Execute Commands**  | ✅ Built-in terminal | ✅ kubectl exec |
| **Resource Graphs**   | ✅ Yes               | ❌ No           |
| **Speed**             | ⚠️ Slower            | ✅ Fast         |
| **Automation**        | ❌ No                | ✅ Yes          |

**Best Practice:** Use both!

- **Dashboard** for visualization and exploration
- **kubectl** for automation and scripts

---

## 🎯 **Your Next Steps**

1. ✅ **Login** with the token above
2. ✅ **Select "todo-app" namespace**
3. ✅ **Navigate to Pods**
4. ✅ **Click on each pod to explore**
5. ✅ **View logs** to see what's happening
6. ✅ **Check Services** to see endpoints
7. ✅ **Explore ConfigMaps and Secrets**

---

## 📱 **Alternative: Lens Desktop**

If you want an even better UI, try **Lens**:

1. **Download:** https://k8slens.dev/
2. **Install** and launch
3. **Auto-detects** your Docker Desktop cluster
4. **Better UI** than Kubernetes Dashboard
5. **Built-in terminal**, **port forwarding**, **monitoring**

---

## ✅ **Quick Access Summary**

**Dashboard URL:**

```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

**Access Token:**

```
(See token above - copy the entire long string)
```

**Namespace to View:**

```
todo-app
```

---

**🎉 Enjoy exploring your Kubernetes cluster visually!**

Your dashboard is now ready to use. Navigate through the UI to see all your pods, deployments, services, and more!

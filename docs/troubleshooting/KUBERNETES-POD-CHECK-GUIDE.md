# 🔍 How to Check Kubernetes Pods Status

## ✅ Quick Reference Guide

### 🎯 **Most Common Commands**

#### 1. **Basic Pod Status Check**

```powershell
# Check pods in a specific namespace
kubectl get pods -n todo-app

# Check pods in all namespaces
kubectl get pods --all-namespaces

# Check pods in current namespace
kubectl get pods
```

**Output Explanation:**

```
NAME                        READY   STATUS    RESTARTS   AGE
api-gateway-7ff6c6cdfb      1/1     Running   0          171m
```

- **NAME**: Pod name
- **READY**: Containers ready (1/1 means 1 out of 1 is ready)
- **STATUS**: Current state (Running, Pending, CrashLoopBackOff, etc.)
- **RESTARTS**: How many times the pod has restarted
- **AGE**: How long the pod has been running

---

### 📊 **Detailed Pod Information**

#### 2. **Get More Details with `-o wide`**

```powershell
kubectl get pods -n todo-app -o wide
```

Shows additional info:

- Pod IP address
- Node where pod is running
- Nominated node
- Readiness gates

#### 3. **Watch Pods in Real-Time**

```powershell
# Watch for changes (updates automatically)
kubectl get pods -n todo-app --watch

# Or short form
kubectl get pods -n todo-app -w
```

Press `Ctrl+C` to stop watching.

#### 4. **Get Full Pod Details**

```powershell
# Describe a specific pod
kubectl describe pod <POD-NAME> -n todo-app

# Example
kubectl describe pod api-gateway-7ff6c6cdfb-dhjn6 -n todo-app
```

Shows:

- Events
- Container status
- Volume mounts
- Environment variables
- Resource limits
- Conditions

---

### 🔍 **Advanced Filtering**

#### 5. **Filter by Labels**

```powershell
# Get pods with specific label
kubectl get pods -n todo-app -l app=api-gateway

# Multiple labels
kubectl get pods -n todo-app -l app=api-gateway,version=v1
```

#### 6. **Filter by Status**

```powershell
# Get only running pods
kubectl get pods -n todo-app --field-selector=status.phase=Running

# Get pending pods
kubectl get pods -n todo-app --field-selector=status.phase=Pending

# Get failed pods
kubectl get pods -n todo-app --field-selector=status.phase=Failed
```

#### 7. **Sort Pods**

```powershell
# Sort by creation time (newest first)
kubectl get pods -n todo-app --sort-by=.metadata.creationTimestamp

# Sort by name
kubectl get pods -n todo-app --sort-by=.metadata.name

# Sort by restart count
kubectl get pods -n todo-app --sort-by=.status.containerStatuses[0].restartCount
```

---

### 📋 **Different Output Formats**

#### 8. **JSON Format**

```powershell
kubectl get pods -n todo-app -o json
```

#### 9. **YAML Format**

```powershell
kubectl get pods -n todo-app -o yaml
```

#### 10. **Custom Columns**

```powershell
# Show only specific columns
kubectl get pods -n todo-app -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP,NODE:.spec.nodeName
```

#### 11. **JSONPath (Extract Specific Data)**

```powershell
# Get just pod names
kubectl get pods -n todo-app -o jsonpath='{.items[*].metadata.name}'

# Get pod IPs
kubectl get pods -n todo-app -o jsonpath='{.items[*].status.podIP}'

# Get pod status
kubectl get pods -n todo-app -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
```

---

### 🧪 **Check Pod Health**

#### 12. **Check Readiness and Liveness**

```powershell
# Get pod conditions
kubectl get pods -n todo-app -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

#### 13. **View Pod Logs**

```powershell
# View logs from a pod
kubectl logs <POD-NAME> -n todo-app

# Follow logs in real-time
kubectl logs -f <POD-NAME> -n todo-app

# View logs from specific container in pod
kubectl logs <POD-NAME> -n todo-app -c <CONTAINER-NAME>

# View last 50 lines
kubectl logs <POD-NAME> -n todo-app --tail=50

# View logs from previous instance (if pod restarted)
kubectl logs <POD-NAME> -n todo-app --previous
```

**Examples for your app:**

```powershell
# API Gateway logs
kubectl logs -f deployment/api-gateway -n todo-app

# User Service logs
kubectl logs -f deployment/user-service -n todo-app

# Last 100 lines from todo-service
kubectl logs deployment/todo-service -n todo-app --tail=100
```

---

### 🔧 **Troubleshooting Commands**

#### 14. **Check Pod Events**

```powershell
# Get events for all pods
kubectl get events -n todo-app --sort-by=.metadata.creationTimestamp

# Get events for specific pod
kubectl describe pod <POD-NAME> -n todo-app | Select-String -Pattern "Events:" -Context 0,20
```

#### 15. **Check Pod Resource Usage**

```powershell
# Get CPU and memory usage
kubectl top pods -n todo-app

# For specific pod
kubectl top pod <POD-NAME> -n todo-app
```

#### 16. **Execute Commands in Pod**

```powershell
# Run interactive shell in pod
kubectl exec -it <POD-NAME> -n todo-app -- sh

# Or bash if available
kubectl exec -it <POD-NAME> -n todo-app -- bash

# Run single command
kubectl exec <POD-NAME> -n todo-app -- ls -la

# For specific container in pod
kubectl exec -it <POD-NAME> -n todo-app -c <CONTAINER-NAME> -- sh
```

**Examples:**

```powershell
# Access PostgreSQL
kubectl exec -it deployment/postgres -n todo-app -- psql -U postgres -d todoapp

# Access Redis
kubectl exec -it deployment/redis -n todo-app -- redis-cli

# Check files in user-service
kubectl exec deployment/user-service -n todo-app -- ls -la /app
```

---

### 📊 **Check All Resources**

#### 17. **Get Everything in Namespace**

```powershell
# View all resources
kubectl get all -n todo-app

# More detailed view
kubectl get all -n todo-app -o wide
```

#### 18. **Check Deployments Status**

```powershell
kubectl get deployments -n todo-app

# With replica count
kubectl get deployments -n todo-app -o wide
```

#### 19. **Check Services**

```powershell
kubectl get services -n todo-app

# Or short form
kubectl get svc -n todo-app
```

#### 20. **Check Everything Related to Pods**

```powershell
# Pods
kubectl get pods -n todo-app

# ReplicaSets (manages pods)
kubectl get replicasets -n todo-app

# Deployments (manages replicasets)
kubectl get deployments -n todo-app

# StatefulSets (if any)
kubectl get statefulsets -n todo-app

# DaemonSets (if any)
kubectl get daemonsets -n todo-app
```

---

### 🎨 **Formatted Output Examples**

#### **Create a Nice Summary**

```powershell
# PowerShell script for formatted output
kubectl get pods -n todo-app -o json | ConvertFrom-Json |
  Select-Object -ExpandProperty items |
  ForEach-Object {
    [PSCustomObject]@{
      Name = $_.metadata.name
      Status = $_.status.phase
      Ready = "$($_.status.containerStatuses[0].ready)"
      Restarts = $_.status.containerStatuses[0].restartCount
      IP = $_.status.podIP
      Age = ((Get-Date) - [DateTime]$_.metadata.creationTimestamp).ToString("hh\:mm\:ss")
    }
  } | Format-Table -AutoSize
```

---

### 🚦 **Understanding Pod Status**

#### **Common Pod States:**

| Status                | Meaning                              | Action                    |
| --------------------- | ------------------------------------ | ------------------------- |
| **Running**           | ✅ Pod is running normally           | None needed               |
| **Pending**           | ⏳ Pod is waiting to be scheduled    | Check node resources      |
| **ContainerCreating** | 🔄 Containers are being created      | Wait, or check events     |
| **CrashLoopBackOff**  | ❌ Pod keeps crashing and restarting | Check logs                |
| **Error**             | ❌ Pod encountered an error          | Check logs and events     |
| **Completed**         | ✅ Pod completed successfully (Jobs) | None needed               |
| **Terminating**       | 🔄 Pod is being terminated           | Wait                      |
| **ImagePullBackOff**  | ❌ Can't pull container image        | Check image name/registry |
| **ErrImagePull**      | ❌ Error pulling image               | Check image exists        |
| **Unknown**           | ❓ Pod state unknown                 | Check node connectivity   |

---

### 📱 **Quick Check Scripts**

#### **Create: `check-pods.ps1`**

```powershell
# Quick Pod Status Check
Write-Host "`n=== Todo App Pod Status ===" -ForegroundColor Cyan

$pods = kubectl get pods -n todo-app -o json | ConvertFrom-Json

Write-Host "`nTotal Pods: $($pods.items.Count)" -ForegroundColor Green

foreach ($pod in $pods.items) {
    $name = $pod.metadata.name
    $status = $pod.status.phase
    $ready = "$($pod.status.containerStatuses[0].ready)"
    $restarts = $pod.status.containerStatuses[0].restartCount

    $color = if ($status -eq "Running" -and $ready -eq "True") { "Green" }
             elseif ($status -eq "Pending") { "Yellow" }
             else { "Red" }

    Write-Host "  $name" -NoNewline
    Write-Host " - $status ($ready) [Restarts: $restarts]" -ForegroundColor $color
}

Write-Host ""
```

**Run it:**

```powershell
.\check-pods.ps1
```

---

### 🔥 **Your Current Pod Status**

Based on your current deployment:

```
✅ api-gateway              - Running (1/1) - 27 restarts
✅ frontend                 - Running (1/1) - 0 restarts
✅ notification-service     - Running (1/1) - 0 restarts
✅ postgres                 - Running (1/1) - 0 restarts
✅ redis                    - Running (1/1) - 0 restarts
✅ todo-service             - Running (1/1) - 0 restarts
✅ user-service             - Running (1/1) - 0 restarts
```

**All pods are running successfully! ✅**

Note: API Gateway has 27 restarts - you might want to check its logs:

```powershell
kubectl logs deployment/api-gateway -n todo-app --tail=50
```

---

### 🎯 **Quick Commands Summary**

```powershell
# Basic check
kubectl get pods -n todo-app

# Detailed view
kubectl get pods -n todo-app -o wide

# Watch in real-time
kubectl get pods -n todo-app --watch

# View logs
kubectl logs -f deployment/api-gateway -n todo-app

# Describe pod
kubectl describe pod <POD-NAME> -n todo-app

# Check all resources
kubectl get all -n todo-app

# Resource usage
kubectl top pods -n todo-app

# Execute command in pod
kubectl exec -it <POD-NAME> -n todo-app -- sh

# Get events
kubectl get events -n todo-app --sort-by=.metadata.creationTimestamp
```

---

**💡 Tip:** Add these to your PowerShell profile for quick access:

```powershell
# Add to: $PROFILE
function Get-TodoPods { kubectl get pods -n todo-app -o wide }
function Watch-TodoPods { kubectl get pods -n todo-app --watch }
function Get-TodoAll { kubectl get all -n todo-app }

# Use them:
Get-TodoPods
Watch-TodoPods
Get-TodoAll
```

---

**🎉 All your pods are running! You're good to go!**

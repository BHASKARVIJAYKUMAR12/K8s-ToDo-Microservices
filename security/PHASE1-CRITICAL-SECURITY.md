# Phase 1: Critical Security Implementation

## 🔒 **Immediate Security Fixes**

### **Step 1: Secrets Management with Google Secret Manager**

#### Create Secrets

```bash
# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com

# Create secrets
gcloud secrets create postgres-password --data-file=-
echo "your-super-secure-db-password" | gcloud secrets create postgres-password --data-file=-

gcloud secrets create jwt-secret --data-file=-
echo "your-256-bit-jwt-secret-key-here" | gcloud secrets create jwt-secret --data-file=-

gcloud secrets create redis-password --data-file=-
echo "your-secure-redis-password" | gcloud secrets create redis-password --data-file=-
```

#### Grant Access to GKE

```bash
# Get your GKE service account
PROJECT_ID=$(gcloud config get-value project)
GKE_SA="${PROJECT_ID}.svc.id.goog[default/default]"

# Grant secret accessor role
gcloud secrets add-iam-policy-binding postgres-password \
  --member="serviceAccount:${GKE_SA}" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding jwt-secret \
  --member="serviceAccount:${GKE_SA}" \
  --role="roles/secretmanager.secretAccessor"
```

### **Step 2: HTTPS/TLS Configuration**

#### Install cert-manager

```bash
# Install cert-manager for automatic SSL certificates
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s
```

#### Configure Let's Encrypt

```yaml
# letsencrypt-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@company.com # CHANGE THIS
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

### **Step 3: Enhanced Authentication**

#### JWT Security Configuration

```yaml
# secure-jwt-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: jwt-config
data:
  JWT_ALGORITHM: "HS256"
  JWT_EXPIRY: "15m"
  JWT_REFRESH_EXPIRY: "7d"
  JWT_ISSUER: "todo-app-production"
  JWT_AUDIENCE: "todo-app-users"
```

#### Rate Limiting Configuration

```yaml
# rate-limit-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: rate-limit-config
data:
  RATE_LIMIT_WINDOW: "15" # 15 minutes
  RATE_LIMIT_MAX: "100" # 100 requests per window
  RATE_LIMIT_SKIP_SUCCESS: "true"
```

### **Step 4: Database Security**

#### PostgreSQL Production Configuration

```yaml
# postgres-secure-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
data:
  POSTGRES_DB: "todoapp_prod"
  POSTGRES_USER: "todoapp_user"
  # Password comes from Secret Manager
  POSTGRES_SSL_MODE: "require"
  POSTGRES_MAX_CONNECTIONS: "100"
  POSTGRES_SHARED_BUFFERS: "256MB"
```

#### Database SSL Configuration

```bash
# Generate SSL certificates for PostgreSQL
kubectl create secret tls postgres-ssl-certs \
  --cert=path/to/server.crt \
  --key=path/to/server.key
```

### **Step 5: Network Security Policies**

#### Default Deny Network Policy

```yaml
# network-policy-default-deny.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

#### Application-Specific Network Policies

```yaml
# network-policy-api-gateway.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-gateway-netpol
spec:
  podSelector:
    matchLabels:
      app: api-gateway
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: todo-service
      ports:
        - protocol: TCP
          port: 3001
    - to:
        - podSelector:
            matchLabels:
              app: user-service
      ports:
        - protocol: TCP
          port: 3002
```

### **Step 6: Pod Security Standards**

#### Pod Security Policy

```yaml
# pod-security-policy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: todo-app-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - "configMap"
    - "emptyDir"
    - "projected"
    - "secret"
    - "downwardAPI"
    - "persistentVolumeClaim"
  runAsUser:
    rule: "MustRunAsNonRoot"
  seLinux:
    rule: "RunAsAny"
  fsGroup:
    rule: "RunAsAny"
```

### **Step 7: RBAC Configuration**

#### Service Accounts and Roles

```yaml
# rbac-config.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: todo-app-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: todo-app-role
rules:
  - apiGroups: [""]
    resources: ["secrets", "configmaps"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: todo-app-binding
subjects:
  - kind: ServiceAccount
    name: todo-app-sa
roleRef:
  kind: Role
  name: todo-app-role
  apiGroup: rbac.authorization.k8s.io
```

## 🚀 **Implementation Commands**

### Quick Security Setup

```bash
# 1. Apply security configurations
kubectl apply -f security/

# 2. Update deployments with security contexts
kubectl patch deployment api-gateway -p '{"spec":{"template":{"spec":{"serviceAccountName":"todo-app-sa"}}}}'

# 3. Enable Pod Security Standards
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
kubectl label namespace default pod-security.kubernetes.io/audit=restricted
kubectl label namespace default pod-security.kubernetes.io/warn=restricted

# 4. Verify security
kubectl auth can-i --list --as=system:serviceaccount:default:todo-app-sa
```

### Security Validation

```bash
# Test network policies
kubectl run test-pod --image=busybox --rm -it -- /bin/sh

# Verify TLS certificates
curl -I https://your-domain.com/health

# Check secret access
kubectl get secrets
kubectl describe secret postgres-password
```

## ⚠️ **Breaking Changes Notice**

These security changes will require:

1. **Application code updates** for secret management
2. **Database connection changes** for SSL
3. **Frontend updates** for HTTPS
4. **Testing environment updates** for new security policies

Estimated implementation time: **2-3 days**
Estimated testing time: **1-2 days**

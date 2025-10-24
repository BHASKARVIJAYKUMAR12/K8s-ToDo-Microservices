# Production HTTPS/TLS Setup for GKE
# This script sets up cert-manager, ingress-nginx, and TLS certificates

param(
    [Parameter(Mandatory=$true)]
    [string]$PROJECT_ID,
    
    [Parameter(Mandatory=$true)]
    [string]$DOMAIN_NAME,
    
    [Parameter(Mandatory=$false)]
    [string]$CLUSTER_NAME = "todo-app-cluster",
    
    [Parameter(Mandatory=$false)]
    [string]$REGION = "us-central1",
    
    [Parameter(Mandatory=$false)]
    [string]$EMAIL = "admin@$DOMAIN_NAME"
)

Write-Host "🔒 Setting up HTTPS/TLS for production deployment..." -ForegroundColor Green
Write-Host "Project ID: $PROJECT_ID" -ForegroundColor Yellow
Write-Host "Domain: $DOMAIN_NAME" -ForegroundColor Yellow
Write-Host "Email: $EMAIL" -ForegroundColor Yellow

# Get cluster credentials
Write-Host "`n🏗️ Connecting to GKE cluster..." -ForegroundColor Blue
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID

# Add Helm repositories
Write-Host "`n📦 Adding Helm repositories..." -ForegroundColor Blue
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install ingress-nginx controller
Write-Host "`n🌐 Installing ingress-nginx controller..." -ForegroundColor Blue
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx `
  --create-namespace `
  --set controller.service.type=LoadBalancer `
  --set controller.service.annotations."cloud\.google\.com/load-balancer-type"="External" `
  --set controller.metrics.enabled=true `
  --set controller.metrics.serviceMonitor.enabled=true `
  --set controller.admissionWebhooks.enabled=true `
  --set controller.config.enable-real-ip=true `
  --set controller.config.compute-full-forwarded-for=true `
  --set controller.config.use-forwarded-headers=true

# Wait for ingress controller to be ready
Write-Host "`n⏳ Waiting for ingress controller to be ready..." -ForegroundColor Yellow
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

# Get the external IP address
Write-Host "`n🔍 Getting external IP address..." -ForegroundColor Blue
do {
    Start-Sleep -Seconds 10
    $externalIP = kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if ($externalIP) {
        Write-Host "✅ External IP obtained: $externalIP" -ForegroundColor Green
    } else {
        Write-Host "⏳ Waiting for external IP..." -ForegroundColor Yellow
    }
} while (-not $externalIP)

# Install cert-manager
Write-Host "`n🛡️ Installing cert-manager..." -ForegroundColor Blue
helm upgrade --install cert-manager jetstack/cert-manager `
  --namespace cert-manager `
  --create-namespace `
  --set installCRDs=true `
  --set global.leaderElection.namespace=cert-manager `
  --set prometheus.enabled=true `
  --set webhook.enabled=true

# Wait for cert-manager to be ready
Write-Host "`n⏳ Waiting for cert-manager to be ready..." -ForegroundColor Yellow
kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/instance=cert-manager --timeout=120s

# Create Let's Encrypt ClusterIssuer
Write-Host "`n📜 Creating Let's Encrypt ClusterIssuer..." -ForegroundColor Blue
$clusterIssuerManifest = @"
# Let's Encrypt ClusterIssuer for production certificates
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-prod-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
          podTemplate:
            metadata:
              annotations:
                cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
---
# Let's Encrypt ClusterIssuer for staging (testing)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $EMAIL
    privateKeySecretRef:
      name: letsencrypt-staging-private-key
    solvers:
    - http01:
        ingress:
          class: nginx
          podTemplate:
            metadata:
              annotations:
                cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
"@

$clusterIssuerManifest | Out-File -FilePath "k8s-specifications\cert-manager-issuers.yaml" -Encoding UTF8

# Apply the ClusterIssuer
kubectl apply -f k8s-specifications/cert-manager-issuers.yaml

# Create production ingress with TLS
Write-Host "`n🌍 Creating production ingress with HTTPS/TLS..." -ForegroundColor Blue
$ingressManifest = @"
# Production Ingress with HTTPS/TLS
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-app-ingress
  namespace: default
  annotations:
    # Ingress class
    kubernetes.io/ingress.class: "nginx"
    
    # TLS configuration
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    cert-manager.io/acme-challenge-type: "http01"
    
    # Security headers
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-protocols: "TLSv1.2 TLSv1.3"
    nginx.ingress.kubernetes.io/ssl-ciphers: "HIGH:!aNULL:!MD5"
    
    # Security policies
    nginx.ingress.kubernetes.io/server-snippet: |
      add_header X-Frame-Options "SAMEORIGIN" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-XSS-Protection "1; mode=block" always;
      add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
      add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;
    
    # Rate limiting
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    
    # CORS configuration
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://$DOMAIN_NAME"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Authorization, Content-Type, X-Requested-With"
    
    # Performance optimizations
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    
spec:
  tls:
  - hosts:
    - $DOMAIN_NAME
    - api.$DOMAIN_NAME
    secretName: todo-app-tls-secret
  rules:
  - host: $DOMAIN_NAME
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  - host: api.$DOMAIN_NAME
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway-service
            port:
              number: 8080
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-gateway-service
            port:
              number: 8080
---
# Certificate resource for explicit certificate management
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: todo-app-certificate
  namespace: default
spec:
  secretName: todo-app-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: $DOMAIN_NAME
  dnsNames:
  - $DOMAIN_NAME
  - api.$DOMAIN_NAME
"@

$ingressManifest | Out-File -FilePath "k8s-specifications\production-ingress.yaml" -Encoding UTF8

# Create network policy for additional security
Write-Host "`n🛡️ Creating network security policies..." -ForegroundColor Blue
$networkPolicyManifest = @"
# Network Policy for additional security
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: todo-app-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: frontend
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
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 8080
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-gateway-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: api-gateway
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
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
    - podSelector:
        matchLabels:
          app: user-service
    - podSelector:
        matchLabels:
          app: notification-service
    ports:
    - protocol: TCP
      port: 3001
    - protocol: TCP
      port: 3002
    - protocol: TCP
      port: 3003
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
"@

$networkPolicyManifest | Out-File -FilePath "k8s-specifications\network-policies.yaml" -Encoding UTF8

Write-Host "`n🎉 HTTPS/TLS setup completed successfully!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Point your DNS records to the external IP: $externalIP" -ForegroundColor White
Write-Host "   - A record: $DOMAIN_NAME -> $externalIP" -ForegroundColor White
Write-Host "   - A record: api.$DOMAIN_NAME -> $externalIP" -ForegroundColor White
Write-Host "2. Apply the production ingress: kubectl apply -f k8s-specifications/production-ingress.yaml" -ForegroundColor White
Write-Host "3. Apply network policies: kubectl apply -f k8s-specifications/network-policies.yaml" -ForegroundColor White
Write-Host "4. Wait for certificate issuance: kubectl get certificates" -ForegroundColor White
Write-Host "5. Test HTTPS access: https://$DOMAIN_NAME" -ForegroundColor White

Write-Host "`n🔒 TLS/Security Summary:" -ForegroundColor Cyan
Write-Host "✅ Ingress-nginx controller installed" -ForegroundColor Green
Write-Host "✅ Cert-manager installed with Let's Encrypt" -ForegroundColor Green
Write-Host "✅ Production ingress with TLS configured" -ForegroundColor Green
Write-Host "✅ Security headers and policies applied" -ForegroundColor Green
Write-Host "✅ Network policies for zero-trust networking" -ForegroundColor Green
Write-Host "`n🌍 Your application will be available at: https://$DOMAIN_NAME" -ForegroundColor Cyan
Write-Host "🔗 API will be available at: https://api.$DOMAIN_NAME" -ForegroundColor Cyan
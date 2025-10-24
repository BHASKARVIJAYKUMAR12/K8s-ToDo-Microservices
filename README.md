# 🚀 K8s-ToDo-Microservices

A **production-ready** enterprise-grade todo application built with modern microservices architecture, designed to demonstrate cloud-native development practices, Kubernetes orchestration, and DevOps excellence. This project showcases the complete journey from development to production deployment on Google Kubernetes Engine (GKE).

## 🏆 **Project Highlights**

- ✅ **Production-Ready**: Enterprise security, monitoring, and reliability
- ✅ **Cloud-Native**: Kubernetes-native design with auto-scaling and self-healing
- ✅ **DevOps Excellence**: Complete CI/CD pipeline with automated testing and deployment
- ✅ **Microservices Architecture**: Loosely coupled, independently deployable services
- ✅ **Modern Tech Stack**: TypeScript, React, Node.js, PostgreSQL, Redis
- ✅ **Security Hardened**: HTTPS/TLS, secrets management, RBAC, network policies
- ✅ **Observable**: Comprehensive monitoring, logging, and distributed tracing
- ✅ **Scalable**: Horizontal and vertical auto-scaling capabilities

> 🔐 **Security First**: This project implements enterprise-grade security practices including secrets management, HTTPS/TLS, RBAC, and network policies. See [docs/SECURITY.md](./docs/SECURITY.md) for security guidelines.

> 📚 **Documentation Hub**: Complete project documentation available in [docs/README.md](./docs/README.md) - your central guide to all docs, troubleshooting, and resources!

> ⚡ **Quick Start**: Get running in 5 minutes with [QUICK-START.md](./QUICK-START.md)

## 🏗️ **Architecture Overview**

This application follows a **cloud-native microservices architecture** with production-grade patterns:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Production Architecture                   │
├─────────────────────────────────────────────────────────────────┤
│  [Internet] → [Load Balancer] → [Ingress] → [API Gateway]      │
│                                                ↓                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Todo      │  │    User     │  │    Notification         │  │
│  │  Service    │  │  Service    │  │     Service             │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│         │                │                      │              │
│  ┌─────────────┐  ┌─────────────┐         ┌─────────┐          │
│  │ PostgreSQL  │  │ PostgreSQL  │         │  Redis  │          │
│  │  (Primary)  │  │ (Replica)   │         │ (Cache) │          │
│  └─────────────┘  └─────────────┘         └─────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### 🎯 **Microservices Breakdown**

| Service                  | Technology           | Purpose                              | Port | Features                            |
| ------------------------ | -------------------- | ------------------------------------ | ---- | ----------------------------------- |
| **Frontend**             | React + TypeScript   | Modern SPA with Material-UI          | 3000 | Responsive design, state management |
| **API Gateway**          | Node.js + Express    | Request routing, rate limiting, auth | 8080 | Load balancing, circuit breaker     |
| **Todo Service**         | Node.js + TypeScript | CRUD operations, business logic      | 3001 | Data validation, caching            |
| **User Service**         | Node.js + TypeScript | Authentication, user management      | 3002 | JWT tokens, password hashing        |
| **Notification Service** | Node.js + TypeScript | Real-time notifications              | 3003 | WebSocket, push notifications       |
| **PostgreSQL**           | PostgreSQL 15        | Primary database                     | 5432 | ACID compliance, replication        |
| **Redis**                | Redis 7              | Caching and message queue            | 6379 | Session store, pub/sub              |

### 🔧 **Production Features**

- **🛡️ Security**: HTTPS/TLS, secrets management, RBAC, network policies
- **📊 Monitoring**: Prometheus, Grafana, Jaeger tracing, centralized logging
- **🚀 DevOps**: CI/CD pipeline, blue-green deployments, automated testing
- **⚡ Performance**: Auto-scaling, caching, load balancing, CDN
- **🔄 Reliability**: Health checks, circuit breakers, graceful shutdowns
- **📱 Observability**: Distributed tracing, metrics, alerts, dashboards

## 📋 **Prerequisites**

### **Development Environment**

- **Node.js 18+** - Runtime environment
- **Docker** - Container platform
- **Git** - Version control
- **VS Code** - IDE (recommended)

### **Cloud Infrastructure**

- **Google Cloud Platform account** with billing enabled
- **gcloud CLI** - Google Cloud SDK
- **kubectl** - Kubernetes command-line tool
- **Helm 3.x** - Kubernetes package manager

### **Production Tools** (Optional for advanced features)

- **Terraform** - Infrastructure as Code
- **GitHub Actions** - CI/CD pipeline
- **SonarCloud** - Code quality analysis

## 🚀 **Quick Start Guide**

### **Option 1: One-Click Production Deployment**

```bash
# Clone the repository
git clone https://github.com/BHASKARVIJAYKUMAR12/K8s-ToDo-Microservices.git
cd K8s-ToDo-Microservices

# Set your GCP Project ID
export PROJECT_ID=your-gcp-project-id

# Deploy to production (includes security, monitoring, and CI/CD)
./scripts/deployment/deploy-production.ps1 $PROJECT_ID
```

### **Option 2: Step-by-Step Deployment**

#### **Step 1: Environment Setup**

```bash
# Enable required GCP APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com

# Set project configuration
gcloud config set project $PROJECT_ID
gcloud auth login
```

#### **Step 2: Create Production GKE Cluster**

**🎯 Autopilot (Recommended - Cost Effective)**

```bash
gcloud container clusters create-auto todo-app-autopilot \
  --region us-central1 \
  --release-channel rapid \
  --enable-network-policy \
  --enable-private-nodes
```

**⚡ Standard Cluster (Advanced Control)**

```bash
gcloud container clusters create todo-app-cluster \
  --region us-central1 \
  --num-nodes 3 \
  --machine-type e2-standard-4 \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 10 \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-network-policy \
  --enable-ip-alias \
  --workload-pool=$PROJECT_ID.svc.id.goog
```

#### **Step 3: Connect to Cluster**

```bash
gcloud container clusters get-credentials todo-app-autopilot --region us-central1
kubectl cluster-info
```

#### **Step 4: Build and Deploy Application**

**🔧 Automated Build and Push**

```bash
# Build and push all Docker images to GCR
./scripts/deployment/build-and-push.ps1 $PROJECT_ID

# Update Kubernetes manifests with your image references
./scripts/deployment/update-k8s-manifests.ps1 $PROJECT_ID
```

**🚀 Deploy to Kubernetes**

```bash
# Deploy all services and dependencies
kubectl apply -f k8s-specifications/

# Verify deployment status
kubectl get pods,services,ingress
```

#### **Step 5: Production Features Setup**

**🔐 Security Hardening**

```bash
# Deploy security configurations
kubectl apply -f security/

# Verify security policies
kubectl get networkpolicies,podsecuritypolicies
```

**📊 Monitoring Stack**

```bash
# Deploy monitoring and observability
kubectl apply -f monitoring/

# Access Grafana dashboard
kubectl port-forward -n monitoring svc/grafana 3000:80
```

**🌐 External Access Setup**

```bash
# Install ingress controller with TLS
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.metrics.enabled=true

# Deploy application ingress with HTTPS
kubectl apply -f k8s-specifications/ingress.yaml

# Get external IP
kubectl get ingress -n default
```

## 💻 **Local Development**

### **🐳 Docker Compose (Recommended)**

```bash
# Start all services with dependencies
docker-compose up --build

# Access the application
open http://localhost:3000  # Frontend
open http://localhost:8080  # API Gateway
```

### **📱 Development URLs**

- **Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:8080
- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686

### **🔧 Manual Development Setup**

**1. Infrastructure Services**

```bash
# Start PostgreSQL
docker run -d --name postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=todoapp \
  -p 5432:5432 postgres:15-alpine

# Start Redis
docker run -d --name redis -p 6379:6379 redis:7-alpine
```

**2. Application Services**

```bash
# Install all dependencies
npm run install:all

# Start all services in development mode
npm run dev

# Or start individually
cd frontend && npm start
cd api-gateway && npm run dev
cd todo-service && npm run dev
cd user-service && npm run dev
cd notification-service && npm run dev
```

### **🧪 Testing**

```bash
# Run all tests
npm test

# Run specific test suites
npm run test:unit          # Unit tests
npm run test:integration   # Integration tests
npm run test:e2e           # End-to-end tests

# Run with coverage
npm run test:coverage
```

## 🔌 **API Documentation**

### **🔐 Authentication Endpoints**

```http
POST /api/auth/register     # Register new user
POST /api/auth/login        # Login user
GET  /api/users/profile     # Get user profile
POST /api/auth/refresh      # Refresh JWT token
POST /api/auth/logout       # Logout user
```

### **📝 Todo Management**

```http
GET    /api/todos           # Get all todos (paginated)
POST   /api/todos           # Create new todo
GET    /api/todos/:id       # Get specific todo
PUT    /api/todos/:id       # Update todo
PATCH  /api/todos/:id/toggle # Toggle completion status
DELETE /api/todos/:id       # Delete todo
GET    /api/todos/stats     # Get user statistics
```

### **📢 Notifications**

```http
GET  /api/notifications/:userId    # Get user notifications
POST /api/notifications/send       # Send notification
PATCH /api/notifications/:id/read  # Mark as read
```

### **🏥 Health & Monitoring**

```http
GET /health                 # Application health check
GET /metrics                # Prometheus metrics
GET /api/version            # API version info
GET /ready                  # Readiness probe
GET /live                   # Liveness probe
```

### **📊 Example API Usage**

**User Registration**

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"john","email":"john@example.com","password":"secure123"}'
```

**Create Todo**

```bash
curl -X POST http://localhost:8080/api/todos \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Learn Kubernetes","description":"Master container orchestration"}'
```

## 📊 **Production Operations**

### **🔍 Monitoring & Observability**

**Application Metrics**

```bash
# Access Grafana dashboards
kubectl port-forward -n monitoring svc/grafana 3000:80
open http://localhost:3000  # admin/admin

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Access Jaeger tracing
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686
```

**Log Analysis**

```bash
# View application logs
kubectl logs -f deployment/api-gateway --tail=100
kubectl logs -f deployment/todo-service --tail=100

# View logs across all pods
kubectl logs -l app=todo-service --tail=100 --prefix=true

# Search logs with context
kubectl logs deployment/api-gateway | grep ERROR
```

### **⚖️ Auto-Scaling & Performance**

**Horizontal Pod Autoscaling**

```bash
# Enable auto-scaling based on CPU
kubectl autoscale deployment todo-service \
  --cpu-percent=70 \
  --min=2 \
  --max=10

# Enable auto-scaling based on memory
kubectl autoscale deployment api-gateway \
  --memory-percent=80 \
  --min=3 \
  --max=15

# Check HPA status
kubectl get hpa
```

**Manual Scaling**

```bash
# Scale specific service
kubectl scale deployment todo-service --replicas=5

# Scale all services
kubectl scale deployment --all --replicas=3
```

**Performance Testing**

```bash
# Load test the API Gateway
kubectl run -i --tty load-test --image=busybox --rm -- sh
# Inside the pod:
wget -O- --post-data='{"title":"Test"}' \
  --header='Content-Type:application/json' \
  http://api-gateway-service:8080/api/todos
```

### **🚨 Troubleshooting & Debugging**

**Health Checks**

```bash
# Check overall cluster health
kubectl get nodes,pods,services,ingress

# Check specific service health
kubectl describe deployment todo-service
kubectl describe pod <pod-name>

# Port forwarding for debugging
kubectl port-forward svc/api-gateway-service 8080:8080
```

**Resource Usage**

```bash
# Check resource consumption
kubectl top nodes
kubectl top pods --sort-by='memory'
kubectl top pods --sort-by='cpu'

# Describe resource limits
kubectl describe deployment todo-service | grep -A 5 "Limits"
```

## Cleanup

```bash
# Delete application resources
kubectl delete -f k8s-specifications/

# Delete ingress controller
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx

# Delete cluster
gcloud container clusters delete todo-app-cluster --region us-central1
```

## 📁 **Project Structure**

> **📋 For detailed project organization, see [PROJECT-STRUCTURE.md](./PROJECT-STRUCTURE.md)**

```
K8s-ToDo-Microservices/
├── 🎯 **Application Services**
│   ├── frontend/                    # React + TypeScript SPA
│   ├── api-gateway/                 # Express + TypeScript Gateway
│   ├── todo-service/                # Business logic microservice
│   ├── user-service/                # Authentication microservice
│   └── notification-service/        # Event-driven notifications
│
├── 🛠️ **Infrastructure & Deployment**
│   ├── k8s-specifications/          # Kubernetes manifests
│   ├── helm-charts/                 # Helm package manager charts
│   ├── monitoring/                  # Observability configurations
│   ├── security/                    # Security policies & configs
│   └── cicd/                       # CI/CD pipeline configurations
│
├── 🤖 **Automation Scripts**
│   ├── scripts/
│   │   ├── deployment/             # Production deployment scripts
│   │   ├── development/            # Local development scripts
│   │   └── infrastructure/         # Infrastructure setup scripts
│
├── 📚 **Documentation**
│   ├── docs/
│   │   ├── deployment/             # Deployment guides & roadmaps
│   │   ├── architecture/           # Architecture diagrams & designs
│   │   ├── operations/             # Operations & maintenance guides
│   │   ├── dev-environment.md      # Development setup
│   │   └── SETUP.md               # Initial setup instructions
│
├── ⚙️ **Configuration Files**
│   ├── docker-compose.yml          # Local development environment
│   ├── package-lock.json          # Node.js dependencies lock
│   └── .gitignore                 # Git ignore patterns
│
└── 📄 **Core Documentation**
    ├── README.md                   # Main project documentation (this file)
    ├── SECURITY.md                 # Security guidelines
    └── PROJECT-STRUCTURE.md        # Detailed project organization
```

### **🔧 Quick Navigation**

| Purpose               | Location                                             | Description                   |
| --------------------- | ---------------------------------------------------- | ----------------------------- |
| **Start Development** | `./scripts/development/start-dev.ps1`                | Local development environment |
| **Deploy Production** | `./scripts/deployment/deploy-production.ps1`         | Complete GKE deployment       |
| **Deployment Guide**  | `./docs/deployment/Production-Deployment-Roadmap.md` | Step-by-step deployment       |
| **Cost Management**   | `./docs/operations/GKE-COST-GUIDE.md`                | Cost optimization guide       |
| **Security Setup**    | `./scripts/infrastructure/setup-secrets.ps1`         | Production secrets            |
| **Architecture View** | `./docs/architecture/architecture-diagram.html`      | Interactive diagrams          |

### **📊 Key Metrics**

- **15+ Microservices & Components**
- **Production-Ready Security** (HTTPS, RBAC, Secrets)
- **Complete Observability** (Metrics, Logs, Tracing)
- **Automated CI/CD Pipeline** (Testing, Deployment, Monitoring)
- **Auto-Scaling Capabilities** (HPA, VPA, Cluster Autoscaler)
- **Multi-Environment Support** (Dev, Staging, Production)

## 💰 **Cost Optimization**

### **💵 Deployment Cost Analysis**

| Environment    | Monthly Cost | Features                  | Use Case                   |
| -------------- | ------------ | ------------------------- | -------------------------- |
| **Learning**   | $60-100      | Basic GKE Autopilot       | Learning & experimentation |
| **Staging**    | $300-500     | Security + Monitoring     | Pre-production testing     |
| **Production** | $800-1500    | Full enterprise features  | Production workloads       |
| **Enterprise** | $1500-4000   | 24/7 support + compliance | Mission-critical systems   |

**💡 Cost Optimization Tips:**

- Use **GKE Autopilot** for automatic resource optimization
- Enable **cluster autoscaling** to scale down during low usage
- Implement **resource requests and limits** for efficient packing
- Use **preemptible instances** for development environments
- Monitor costs with **GCP Budget alerts**

See [GKE-COST-GUIDE.md](./GKE-COST-GUIDE.md) for detailed cost management.

---

## 🤝 **Contributing**

We welcome contributions from the community! Here's how to get started:

### **🚀 Development Process**

```bash
# 1. Fork the repository
git fork https://github.com/BHASKARVIJAYKUMAR12/K8s-ToDo-Microservices.git

# 2. Create a feature branch
git checkout -b feature/amazing-feature

# 3. Make your changes
# Follow the coding standards in .editorconfig

# 4. Run tests
npm test
npm run test:e2e

# 5. Commit with conventional commits
git commit -m "feat: add amazing feature"

# 6. Push and create pull request
git push origin feature/amazing-feature
```

### **📋 Development Guidelines**

- ✅ Write tests for new features
- ✅ Follow TypeScript best practices
- ✅ Update documentation
- ✅ Security scan with `npm audit`
- ✅ Performance testing for major changes

---

## 🔒 **Security & Compliance**

### **🛡️ Security Features**

- **HTTPS/TLS Everywhere** - End-to-end encryption
- **JWT Authentication** - Secure token-based auth
- **RBAC Policies** - Role-based access control
- **Network Policies** - Zero-trust networking
- **Secrets Management** - Google Secret Manager integration
- **Vulnerability Scanning** - Automated security scans

### **📜 Compliance Standards**

- SOC 2 Type II ready
- ISO 27001 compatible
- GDPR privacy controls
- PCI DSS for payments (when implemented)

See [SECURITY.md](./SECURITY.md) for detailed security guidelines.

---

## 📚 **Learning Resources**

### **🎓 What You'll Learn**

- **Microservices Architecture** - Service decomposition and communication
- **Kubernetes Operations** - Container orchestration at scale
- **DevOps Practices** - CI/CD, monitoring, and automation
- **Cloud-Native Patterns** - Scalability, resilience, and observability
- **Production Deployment** - Security, monitoring, and reliability

### **📖 Recommended Reading**

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Microservices Patterns](https://microservices.io/patterns/)
- [Cloud Native Computing Foundation](https://www.cncf.io/)
- [Google Cloud Architecture Center](https://cloud.google.com/architecture)

---

## 📞 **Support & Community**

### **🔧 Getting Help**

- 📖 Check [Troubleshooting Guide](./docs/TROUBLESHOOTING.md)
- 🐛 Report bugs via [GitHub Issues](https://github.com/BHASKARVIJAYKUMAR12/K8s-ToDo-Microservices/issues)
- 💬 Join discussions in [GitHub Discussions](https://github.com/BHASKARVIJAYKUMAR12/K8s-ToDo-Microservices/discussions)
- 📧 Contact: [bhaskarvijayofficial2023@gmail.com]

### **🏆 Acknowledgments**

Special thanks to the open-source community and the following projects that made this possible:

- Kubernetes & Google Kubernetes Engine
- Node.js & React ecosystems
- PostgreSQL & Redis communities
- Prometheus & Grafana projects

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🎯 **Project Status**

[![Build Status](https://github.com/BHASKARVIJAYKUMAR12/K8s-ToDo-Microservices/workflows/CI/badge.svg)](https://github.com/BHASKARVIJAYKUMAR12/K8s-ToDo-Microservices/actions)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=todo-app&metric=security_rating)](https://sonarcloud.io/dashboard?id=todo-app)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=todo-app&metric=coverage)](https://sonarcloud.io/dashboard?id=todo-app)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**🚀 This is more than a todo app - it's a complete microservices platform demonstrating enterprise-grade cloud-native development practices. Perfect for learning Kubernetes, DevOps, and production deployment patterns!**

---

## ⭐ **Star History**

If this project helped you learn Kubernetes and microservices, please consider giving it a star ⭐ to help others discover it!

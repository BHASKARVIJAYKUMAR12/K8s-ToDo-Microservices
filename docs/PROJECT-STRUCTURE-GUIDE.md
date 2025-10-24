# 📚 Complete Project Structure Guide

## 🎯 Project Overview

This is a **microservices-based Todo application** designed for learning Kubernetes deployment. It demonstrates modern cloud-native architecture with TypeScript, Docker, and Kubernetes.

**Tech Stack:**

- Frontend: React + TypeScript
- Backend: Node.js + Express + TypeScript
- Database: PostgreSQL
- Cache: Redis
- Orchestration: Kubernetes
- Containerization: Docker

---

## 📂 Root Directory Structure

```
K8s-ToDo-Microservices/
├── api-gateway/              # API Gateway service
├── frontend/                 # React frontend application
├── user-service/             # User authentication service
├── todo-service/             # Todo CRUD operations service
├── notification-service/     # Notification handling service
├── k8s-specifications/       # Kubernetes deployment manifests
├── helm-charts/              # Helm charts for deployment
├── scripts/                  # Automation scripts
├── docs/                     # Project documentation
├── cicd/                     # CI/CD pipeline configurations
├── monitoring/               # Monitoring and observability
├── security/                 # Security configurations
├── docker-compose.yml        # Local development with Docker Compose
└── README.md                 # Main project documentation
```

---

## 🚪 API Gateway (`api-gateway/`)

**Purpose:** Central entry point for all client requests. Routes requests to appropriate microservices.

### Structure:

```
api-gateway/
├── src/
│   ├── index.ts              # Main server entry point
│   ├── middleware/           # Custom middleware (CORS, auth, logging)
│   └── routes/               # Route definitions and forwarding logic
├── Dockerfile                # Container image definition
├── package.json              # Node.js dependencies
└── tsconfig.json             # TypeScript configuration
```

### Key Responsibilities:

- **Request Routing**: Forwards `/api/auth/*` to user-service, `/api/todos/*` to todo-service
- **CORS Handling**: Manages cross-origin requests from frontend
- **Authentication Gateway**: Can validate tokens before forwarding
- **Rate Limiting**: Controls request frequency
- **Load Distribution**: Routes to healthy service instances

### Environment Variables:

- `PORT`: Server port (default: 8080)
- `USER_SERVICE_URL`: URL of user service
- `TODO_SERVICE_URL`: URL of todo service
- `ALLOWED_ORIGINS`: CORS allowed origins

---

## 🎨 Frontend (`frontend/`)

**Purpose:** User interface for the todo application. Built with React and TypeScript.

### Structure:

```
frontend/
├── src/
│   ├── App.tsx               # Main application component
│   ├── index.tsx             # React entry point
│   ├── components/           # Reusable UI components
│   │   ├── TodoList.tsx      # Todo list display
│   │   ├── TodoItem.tsx      # Individual todo item
│   │   ├── LoginForm.tsx     # User login form
│   │   └── RegisterForm.tsx  # User registration form
│   ├── contexts/             # React Context API (state management)
│   │   └── AuthContext.tsx   # Authentication state
│   ├── services/             # API communication
│   │   └── api.ts            # Axios HTTP client configuration
│   └── types/                # TypeScript type definitions
│       └── index.ts          # Shared types (Todo, User, etc.)
├── public/
│   └── index.html            # HTML template
├── build/                    # Production build output (generated)
├── Dockerfile                # Multi-stage build (build + nginx)
├── nginx.conf                # Nginx server configuration
├── package.json              # React dependencies
└── tsconfig.json             # TypeScript configuration
```

### Key Features:

- **Authentication UI**: Login and registration forms
- **Todo Management**: Create, read, update, delete todos
- **Real-time Updates**: Optimistic UI updates
- **Responsive Design**: Works on mobile and desktop
- **Token Management**: Stores JWT in localStorage

### Build Process:

1. **Build Stage**: `npm run build` creates optimized production bundle
2. **Runtime Stage**: Nginx serves static files
3. **Environment Variables**: `REACT_APP_API_URL` configures API endpoint

---

## 👤 User Service (`user-service/`)

**Purpose:** Handles user authentication, registration, and profile management.

### Structure:

```
user-service/
├── src/
│   ├── index.ts              # Main server entry point
│   ├── routes/               # Authentication routes
│   │   └── auth.ts           # /register, /login, /profile endpoints
│   ├── models/               # Data models
│   │   └── User.ts           # User model definition
│   ├── middleware/           # Authentication middleware
│   │   └── auth.ts           # JWT verification
│   └── database/             # Database connection
│       └── connection.ts     # PostgreSQL connection pool
├── Dockerfile                # Container image definition
├── package.json              # Node.js dependencies
└── tsconfig.json             # TypeScript configuration
```

### API Endpoints:

- `POST /api/auth/register`: Create new user account
- `POST /api/auth/login`: Authenticate and get JWT token
- `GET /api/auth/profile`: Get current user profile (requires auth)
- `PUT /api/auth/profile`: Update user profile (requires auth)

### Database Schema:

```sql
users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
)
```

### Security:

- **Password Hashing**: Uses bcrypt for secure password storage
- **JWT Tokens**: Issues JWT for authenticated sessions
- **Input Validation**: Validates email format, password strength

---

## ✅ Todo Service (`todo-service/`)

**Purpose:** Manages todo items - create, read, update, delete operations.

### Structure:

```
todo-service/
├── src/
│   ├── index.ts              # Main server entry point
│   ├── routes/               # Todo routes
│   │   └── todos.ts          # CRUD endpoints
│   ├── models/               # Data models
│   │   └── Todo.ts           # Todo model definition
│   ├── middleware/           # Authentication middleware
│   │   └── auth.ts           # JWT verification
│   └── database/             # Database connection
│       └── connection.ts     # PostgreSQL connection pool
├── Dockerfile                # Container image definition
├── package.json              # Node.js dependencies
└── tsconfig.json             # TypeScript configuration
```

### API Endpoints:

- `GET /api/todos`: List all todos for authenticated user
- `POST /api/todos`: Create new todo
- `GET /api/todos/:id`: Get specific todo
- `PUT /api/todos/:id`: Update todo (title, completed status)
- `DELETE /api/todos/:id`: Delete todo

### Database Schema:

```sql
todos (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
)
```

### Features:

- **User Isolation**: Users only see their own todos
- **Validation**: Ensures required fields are present
- **Timestamps**: Tracks creation and update times

---

## 🔔 Notification Service (`notification-service/`)

**Purpose:** Handles notifications for todo updates, reminders, and user activities.

### Structure:

```
notification-service/
├── src/
│   └── index.ts              # Main server with event listeners
├── Dockerfile                # Container image definition
├── package.json              # Node.js dependencies
└── tsconfig.json             # TypeScript configuration
```

### Responsibilities:

- **Event Processing**: Listens to Redis pub/sub for events
- **Email Notifications**: Sends emails for important events
- **Push Notifications**: (Future) Push to mobile devices
- **Websocket Updates**: (Future) Real-time UI updates

### Event Types:

- `todo.created`: New todo created
- `todo.completed`: Todo marked as complete
- `user.registered`: New user registration

---

## ☸️ Kubernetes Specifications (`k8s-specifications/`)

**Purpose:** Production-grade Kubernetes manifests for deploying all services.

### Structure:

```
k8s-specifications/
├── frontend-deployment.yaml           # Frontend deployment & service
├── api-gateway-deployment.yaml        # API Gateway deployment & service
├── user-service-deployment.yaml       # User service deployment & service
├── todo-service-deployment.yaml       # Todo service deployment & service
├── notification-service-deployment.yaml # Notification deployment & service
├── postgres-deployment.yaml           # PostgreSQL stateful deployment
├── redis-deployment.yaml              # Redis deployment
└── ingress.yaml                       # Ingress for external access
```

### Each Deployment File Contains:

1. **ConfigMap**: Environment variables and configuration
2. **Secret**: Sensitive data (passwords, tokens)
3. **Deployment**: Pod specifications, replicas, resource limits
4. **Service**: ClusterIP service for internal communication
5. **Health Checks**: Liveness and readiness probes

### Example: `frontend-deployment.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
data:
  REACT_APP_API_URL: "/api" # Relative URL for ingress

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: frontend:latest
          ports:
            - containerPort: 80
          envFrom:
            - configMapRef:
                name: frontend-config

---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: ClusterIP
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
```

---

## 📦 Helm Charts (`helm-charts/`)

**Purpose:** Package manager for Kubernetes. Simplifies deployment with templates.

### Structure:

```
helm-charts/
└── todo-app/
    ├── Chart.yaml            # Chart metadata
    ├── values.yaml           # Default configuration values
    ├── templates/            # Kubernetes manifest templates
    │   ├── frontend.yaml
    │   ├── api-gateway.yaml
    │   ├── user-service.yaml
    │   ├── todo-service.yaml
    │   ├── postgres.yaml
    │   └── redis.yaml
    └── values-dev.yaml       # Development overrides
```

### Benefits:

- **Parameterization**: Single values file for all configurations
- **Versioning**: Track deployment versions
- **Rollback**: Easy rollback to previous versions
- **Environment Management**: Different values for dev/staging/prod

### Usage:

```bash
# Install/upgrade
helm upgrade --install todo-app ./helm-charts/todo-app -f values-dev.yaml

# Rollback
helm rollback todo-app 1

# Uninstall
helm uninstall todo-app
```

---

## 🤖 Scripts (`scripts/`)

**Purpose:** Automation scripts for development, deployment, and infrastructure management.

### Structure:

```
scripts/
├── development/              # Local development scripts
│   ├── start-dev.ps1        # Start all services locally
│   ├── start-dev.sh         # Linux version
│   ├── local-build.ps1      # Build all Docker images
│   ├── deploy-local-k8s.ps1 # Deploy to local Kubernetes
│   └── test-local-deployment.ps1 # Test deployment health
│
├── deployment/              # Production deployment scripts
│   ├── build-and-push.ps1  # Build and push to registry
│   ├── deploy-to-gke.ps1   # Deploy to Google Kubernetes Engine
│   ├── deploy-production.ps1 # Production deployment orchestration
│   └── update-k8s-manifests.ps1 # Update image tags in manifests
│
└── infrastructure/          # Infrastructure setup scripts
    ├── setup-secrets.ps1    # Create Kubernetes secrets
    ├── setup-https.ps1      # Configure SSL certificates
    └── setup-monitoring.ps1 # Deploy monitoring stack
```

### Key Scripts:

#### `development/start-dev.ps1`

Starts all services locally with docker-compose:

```powershell
docker-compose up -d
```

#### `development/local-build.ps1`

Builds all Docker images:

```powershell
docker build -t frontend:latest ./frontend
docker build -t api-gateway:latest ./api-gateway
docker build -t user-service:latest ./user-service
docker build -t todo-service:latest ./todo-service
```

#### `deployment/deploy-to-gke.ps1`

Deploys to Google Cloud:

```powershell
# Configure kubectl for GKE
gcloud container clusters get-credentials todo-cluster

# Apply all manifests
kubectl apply -f k8s-specifications/
```

---

## 📖 Documentation (`docs/`)

**Purpose:** Comprehensive project documentation.

### Structure:

```
docs/
├── SETUP.md                  # Initial setup instructions
├── dev-environment.md        # Development environment setup
│
├── architecture/             # Architecture documentation
│   └── architecture-diagram.html # Visual architecture diagram
│
└── deployment/               # Deployment guides
    ├── Local-Kubernetes-Testing.md # Local K8s testing guide
    ├── Production-Deployment-Roadmap.md # Production deployment plan
    ├── PRODUCTION-READINESS.md # Production checklist
    └── PRODUCTION-TRANSFORMATION-SUMMARY.md # Transformation notes
```

### Key Documents:

#### `SETUP.md`

- Prerequisites (Node.js, Docker, kubectl)
- Installation steps
- First-time setup

#### `dev-environment.md`

- IDE setup (VS Code extensions)
- Environment variables
- Local development workflow

#### `deployment/Local-Kubernetes-Testing.md`

- Setting up local Kubernetes (Docker Desktop/Minikube)
- Building images
- Deploying to local cluster
- Port forwarding for testing

---

## 🔄 CI/CD (`cicd/`)

**Purpose:** Continuous Integration and Continuous Deployment configurations.

### Structure:

```
cicd/
└── CI-CD-PIPELINE.md         # Pipeline documentation
```

### Typical CI/CD Pipeline:

1. **Build Stage**: Build Docker images for all services
2. **Test Stage**: Run unit tests and integration tests
3. **Push Stage**: Push images to container registry
4. **Deploy Stage**: Deploy to Kubernetes cluster
5. **Verify Stage**: Run smoke tests

### Future Integrations:

- GitHub Actions workflows
- Jenkins pipeline
- GitLab CI
- ArgoCD for GitOps

---

## 📊 Monitoring (`monitoring/`)

**Purpose:** Observability stack for monitoring application health and performance.

### Structure:

```
monitoring/
├── MONITORING-STACK.md       # Monitoring setup guide
├── prometheus-config.yaml    # Prometheus configuration
└── grafana-dashboards.yaml   # Grafana dashboard definitions
```

### Components:

#### Prometheus

- **Metrics Collection**: Scrapes metrics from all services
- **Alerting**: Triggers alerts based on thresholds
- **Time Series**: Stores historical metrics data

#### Grafana

- **Dashboards**: Visual representation of metrics
- **Alerts**: Visual alerts and notifications
- **Panels**: CPU, memory, request rate, error rate

### Metrics Tracked:

- **Application Metrics**: Request rate, response time, error rate
- **Infrastructure Metrics**: CPU, memory, disk usage
- **Database Metrics**: Connection pool, query performance
- **Custom Metrics**: Todos created, user registrations

---

## 🔒 Security (`security/`)

**Purpose:** Security configurations and best practices.

### Structure:

```
security/
└── PHASE1-CRITICAL-SECURITY.md # Security implementation guide
```

### Security Measures:

#### Phase 1 - Critical

- ✅ Password hashing with bcrypt
- ✅ JWT token authentication
- ✅ HTTPS/TLS encryption
- ✅ Input validation
- ✅ SQL injection prevention

#### Phase 2 - Important

- Rate limiting
- API key rotation
- Secret management (Vault)
- Security headers (HSTS, CSP)
- Dependency scanning

#### Phase 3 - Enhanced

- Penetration testing
- Security audits
- Compliance certifications

---

## 🐳 Docker Compose (`docker-compose.yml`)

**Purpose:** Local development environment with all services.

### Structure:

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: tododb
      POSTGRES_USER: todouser
      POSTGRES_PASSWORD: todopass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  user-service:
    build: ./user-service
    depends_on:
      - postgres
      - redis
    environment:
      DATABASE_URL: postgresql://todouser:todopass@postgres:5432/tododb
      REDIS_URL: redis://redis:6379
    ports:
      - "3001:3000"

  todo-service:
    build: ./todo-service
    depends_on:
      - postgres
      - redis
    environment:
      DATABASE_URL: postgresql://todouser:todopass@postgres:5432/tododb
      REDIS_URL: redis://redis:6379
    ports:
      - "3002:3000"

  api-gateway:
    build: ./api-gateway
    depends_on:
      - user-service
      - todo-service
    environment:
      USER_SERVICE_URL: http://user-service:3000
      TODO_SERVICE_URL: http://todo-service:3000
    ports:
      - "8080:8080"

  frontend:
    build: ./frontend
    depends_on:
      - api-gateway
    environment:
      REACT_APP_API_URL: http://localhost:8080/api
    ports:
      - "3000:80"

volumes:
  postgres_data:
```

### Usage:

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Rebuild and restart
docker-compose up -d --build
```

---

## 🗂️ Root Documentation Files

### `README.md`

- Project overview
- Quick start guide
- Architecture diagram
- Contributing guidelines

### `PROJECT-STRUCTURE.md`

- Directory structure overview
- Service descriptions

### `KUBERNETES-DEPLOYMENT-SUCCESS.md`

- Successful deployment documentation
- Troubleshooting notes

### `CORS-FIXED-K8S.md`

- CORS issue resolution
- Configuration changes

### `QUICK-ACCESS.md`

- Quick reference for common commands
- Port forwarding commands
- Useful kubectl commands

---

## 🚀 Deployment Flow

### Local Development

```
1. Edit code
2. docker-compose up --build (rebuild and restart)
3. Test at localhost:3000
4. Iterate
```

### Local Kubernetes Testing

```
1. Build images: ./scripts/development/local-build.ps1
2. Deploy: ./scripts/development/deploy-local-k8s.ps1
3. Port forward: kubectl port-forward svc/frontend-service 3000:80
4. Test: Access localhost:3000
```

### Production Deployment

```
1. Build and tag: ./scripts/deployment/build-and-push.ps1
2. Push to registry: docker push <registry>/frontend:v1.0.0
3. Update manifests: ./scripts/deployment/update-k8s-manifests.ps1
4. Deploy: kubectl apply -f k8s-specifications/
5. Verify: kubectl get pods
6. Monitor: Check Grafana dashboards
```

---

## 🔧 Common Operations

### View Logs

```bash
# Specific service
kubectl logs -f deployment/api-gateway -n todo-app

# All pods with label
kubectl logs -l app=frontend -n todo-app --tail=50

# Previous container (after crash)
kubectl logs deployment/user-service --previous -n todo-app
```

### Scale Services

```bash
# Scale frontend to 3 replicas
kubectl scale deployment/frontend --replicas=3 -n todo-app

# Autoscaling
kubectl autoscale deployment/api-gateway --min=2 --max=10 --cpu-percent=80 -n todo-app
```

### Update Configuration

```bash
# Edit ConfigMap
kubectl edit configmap api-gateway-config -n todo-app

# Restart to apply changes
kubectl rollout restart deployment/api-gateway -n todo-app

# Check status
kubectl rollout status deployment/api-gateway -n todo-app
```

### Database Access

```bash
# Connect to PostgreSQL
kubectl exec -it deployment/postgres -n todo-app -- psql -U todouser -d tododb

# Run SQL query
kubectl exec -it deployment/postgres -n todo-app -- psql -U todouser -d tododb -c "SELECT * FROM users;"

# Backup database
kubectl exec deployment/postgres -n todo-app -- pg_dump -U todouser tododb > backup.sql
```

---

## 📝 Environment Variables Reference

### Frontend

- `REACT_APP_API_URL`: API Gateway URL (e.g., `http://localhost:8080/api` or `/api`)

### API Gateway

- `PORT`: Server port (default: 8080)
- `USER_SERVICE_URL`: User service internal URL (e.g., `http://user-service:3000`)
- `TODO_SERVICE_URL`: Todo service internal URL (e.g., `http://todo-service:3000`)
- `ALLOWED_ORIGINS`: CORS allowed origins (comma-separated)
- `JWT_SECRET`: Secret key for JWT validation

### User Service

- `PORT`: Server port (default: 3000)
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `JWT_SECRET`: Secret key for JWT signing
- `JWT_EXPIRES_IN`: Token expiration (e.g., `7d`)
- `BCRYPT_ROUNDS`: Password hashing rounds (default: 10)

### Todo Service

- `PORT`: Server port (default: 3000)
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `JWT_SECRET`: Secret key for JWT validation

### Notification Service

- `PORT`: Server port (default: 3000)
- `REDIS_URL`: Redis connection string
- `SMTP_HOST`: Email server host
- `SMTP_PORT`: Email server port
- `SMTP_USER`: Email username
- `SMTP_PASS`: Email password

---

## 🎓 Learning Objectives

This project is designed to teach:

1. **Microservices Architecture**

   - Service decomposition
   - Inter-service communication
   - API Gateway pattern

2. **Containerization**

   - Docker multi-stage builds
   - Image optimization
   - Container orchestration

3. **Kubernetes**

   - Deployments and Services
   - ConfigMaps and Secrets
   - Ingress and networking
   - Scaling and health checks

4. **DevOps Practices**

   - CI/CD pipelines
   - Infrastructure as Code
   - Monitoring and logging

5. **Cloud Native Development**
   - 12-factor app principles
   - Stateless services
   - Configuration management

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Port Forwarding Issues

**Problem:** Port already in use

```bash
# Find process using port
Get-NetTCPConnection -LocalPort 3000 -State Listen | Select-Object OwningProcess

# Kill process
Stop-Process -Id <PID> -Force
```

#### 2. Image Pull Errors

**Problem:** `ImagePullBackOff` in Kubernetes

```bash
# Check image exists locally
docker images

# Update imagePullPolicy
kubectl patch deployment/frontend -p '{"spec":{"template":{"spec":{"containers":[{"name":"frontend","imagePullPolicy":"IfNotPresent"}]}}}}' -n todo-app
```

#### 3. Database Connection Errors

**Problem:** Services can't connect to PostgreSQL

```bash
# Check PostgreSQL pod
kubectl get pod -l app=postgres -n todo-app

# Check logs
kubectl logs deployment/postgres -n todo-app

# Verify service
kubectl get svc postgres-service -n todo-app
```

#### 4. CORS Errors

**Problem:** Frontend blocked by CORS

```bash
# Update API Gateway ALLOWED_ORIGINS
kubectl edit configmap api-gateway-config -n todo-app

# Add: ALLOWED_ORIGINS: "http://localhost:3000,http://frontend-service"

# Restart API Gateway
kubectl rollout restart deployment/api-gateway -n todo-app
```

---

## 📚 Additional Resources

### Official Documentation

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [React Documentation](https://react.dev/)
- [Node.js Documentation](https://nodejs.org/docs/)

### Tutorials

- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Docker Getting Started](https://docs.docker.com/get-started/)
- [Microservices Patterns](https://microservices.io/patterns/index.html)

### Tools

- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [Helm Documentation](https://helm.sh/docs/)

---

## 🎯 Next Steps

1. **Complete Local Testing**: Ensure all services work locally
2. **Add Unit Tests**: Implement Jest tests for all services
3. **Set Up CI/CD**: Create GitHub Actions workflow
4. **Deploy to Cloud**: Set up GKE cluster and deploy
5. **Add Monitoring**: Configure Prometheus and Grafana
6. **Implement Logging**: Set up ELK stack for centralized logging
7. **Security Hardening**: Implement all Phase 2 security measures
8. **Performance Testing**: Load testing with k6 or JMeter
9. **Documentation**: Create video tutorials and blog posts
10. **Open Source**: Publish to GitHub with proper documentation

---

## 📞 Support

For questions or issues:

- Check existing documentation in `docs/`
- Review troubleshooting section above
- Check GitHub Issues
- Review Kubernetes logs with `kubectl logs`

---

**Last Updated:** October 21, 2025
**Version:** 1.0.0
**Author:** K8s Learning Project Team

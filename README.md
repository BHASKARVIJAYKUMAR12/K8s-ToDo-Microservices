# K8s-ToDo-Microservices

A comprehensive todo application built with microservices architecture for learning Kubernetes deployment on GKE. This project demonstrates modern development practices with TypeScript, React, PostgreSQL, and Redis.

> ⚠️ **Security Notice**: This repository contains example configurations. Never commit real credentials to version control. See [SETUP.md](./SETUP.md) for secure environment configuration.

## Architecture

<img width="860" height="800" alt="todo app architecture" src="https://via.placeholder.com/860x800/2196F3/ffffff?text=Todo+App+Microservices+Architecture" />

### Services Overview

- **Frontend Service**: React + TypeScript UI (Port 3000)
- **API Gateway**: Request router and load balancer (Port 8080)
- **Todo Service**: CRUD operations for todos (Port 3001)
- **User Service**: Authentication and user management (Port 3002)
- **Notification Service**: Real-time notifications (Port 3003)
- **PostgreSQL**: Primary database for persistent storage
- **Redis**: Caching and message queue

## Prerequisites

- Google Cloud Platform account
- `gcloud` CLI installed and configured
- Docker installed
- `kubectl` installed
- Node.js 18+ (for local development)
- Git

## Step 1: Enable Container API

```bash
gcloud services enable container.googleapis.com
```

## Step 2: Create a GKE Cluster

### Option A: Standard GKE cluster

```bash
gcloud container clusters create todo-app-cluster \
  --region us-central1 \
  --num-nodes 3 \
  --machine-type e2-standard-4 \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 5
```

### Option B: GKE Autopilot (Recommended)

```bash
gcloud container clusters create-auto todo-app-autopilot \
  --region us-central1
```

## Step 3: Connect to the Cluster

```bash
# For standard cluster
gcloud container clusters get-credentials todo-app-cluster --region us-central1

# For autopilot cluster
gcloud container clusters get-credentials todo-app-autopilot --region us-central1
```

## Step 4: Clone and Setup

```bash
git clone https://github.com/YOUR-USERNAME/K8s-ToDo-Microservices.git
cd K8s-ToDo-Microservices

# ⚠️ IMPORTANT: Configure environment variables
cp user-service/.env.example user-service/.env
cp todo-service/.env.example todo-service/.env
cp api-gateway/.env.example api-gateway/.env
cp notification-service/.env.example notification-service/.env

# Edit .env files with your actual credentials
# See SETUP.md for detailed configuration instructions
```

## Step 5: Build and Push Docker Images

```bash
# Set your project ID
export PROJECT_ID=your-gcp-project-id

# Build and push all images
docker build -t gcr.io/$PROJECT_ID/frontend:latest ./frontend
docker build -t gcr.io/$PROJECT_ID/api-gateway:latest ./api-gateway
docker build -t gcr.io/$PROJECT_ID/todo-service:latest ./todo-service
docker build -t gcr.io/$PROJECT_ID/user-service:latest ./user-service
docker build -t gcr.io/$PROJECT_ID/notification-service:latest ./notification-service

# Push to Google Container Registry
docker push gcr.io/$PROJECT_ID/frontend:latest
docker push gcr.io/$PROJECT_ID/api-gateway:latest
docker push gcr.io/$PROJECT_ID/todo-service:latest
docker push gcr.io/$PROJECT_ID/user-service:latest
docker push gcr.io/$PROJECT_ID/notification-service:latest
```

## Step 6: Update Kubernetes Manifests

Update the image references in the deployment files to use your GCR images:

```bash
# Replace image names in k8s-specifications/*.yaml files
sed -i "s|frontend:latest|gcr.io/$PROJECT_ID/frontend:latest|g" k8s-specifications/frontend-deployment.yaml
sed -i "s|api-gateway:latest|gcr.io/$PROJECT_ID/api-gateway:latest|g" k8s-specifications/api-gateway-deployment.yaml
sed -i "s|todo-service:latest|gcr.io/$PROJECT_ID/todo-service:latest|g" k8s-specifications/todo-service-deployment.yaml
sed -i "s|user-service:latest|gcr.io/$PROJECT_ID/user-service:latest|g" k8s-specifications/user-service-deployment.yaml
sed -i "s|notification-service:latest|gcr.io/$PROJECT_ID/notification-service:latest|g" k8s-specifications/notification-service-deployment.yaml
```

## Step 7: Deploy to Kubernetes

```bash
# Deploy all services
kubectl apply -f k8s-specifications/

# Verify deployment
kubectl get all
```

## Step 8: Set Up Ingress Controller

```bash
# Create ingress-nginx namespace
kubectl create namespace ingress-nginx

# Add ingress-nginx Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install ingress controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer
```

## Step 9: Deploy Application Ingress

```bash
# Apply ingress configuration
kubectl apply -f k8s-specifications/ingress.yaml

# Get external IP
kubectl get ingress
```

## Local Development

### Using Docker Compose

```bash
# Start all services locally
docker-compose up --build

# Access the application
# Frontend: http://localhost:3000
# API Gateway: http://localhost:8080
```

### Manual Setup

1. **Start PostgreSQL and Redis**:

```bash
# PostgreSQL
docker run -d --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 postgres:15-alpine

# Redis
docker run -d --name redis -p 6379:6379 redis:7-alpine
```

2. **Install dependencies and start services**:

```bash
# Frontend
cd frontend && npm install && npm start

# API Gateway
cd api-gateway && npm install && npm run dev

# Todo Service
cd todo-service && npm install && npm run dev

# User Service
cd user-service && npm install && npm run dev

# Notification Service
cd notification-service && npm install && npm run dev
```

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Todos

- `GET /api/todos` - Get all todos
- `POST /api/todos` - Create new todo
- `PUT /api/todos/:id` - Update todo
- `PATCH /api/todos/:id/toggle` - Toggle completion
- `DELETE /api/todos/:id` - Delete todo

### Health Checks

- `GET /health` - Health check for all services

## Monitoring and Debugging

```bash
# Check pod status
kubectl get pods

# View logs
kubectl logs -f deployment/todo-service

# Check service endpoints
kubectl get services

# Port forward for debugging
kubectl port-forward svc/api-gateway-service 8080:8080
```

## Scaling

```bash
# Scale specific service
kubectl scale deployment todo-service --replicas=5

# Auto-scaling (HPA)
kubectl autoscale deployment todo-service --cpu-percent=70 --min=2 --max=10
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

## Project Structure

```
todo-app-kubernetes/
├── frontend/                 # React TypeScript frontend
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── services/        # API service layer
│   │   └── types/           # TypeScript interfaces
│   ├── Dockerfile
│   └── package.json
├── api-gateway/             # Express TypeScript API Gateway
│   ├── src/
│   │   ├── middleware/      # Authentication middleware
│   │   └── routes/          # Route handlers
│   ├── Dockerfile
│   └── package.json
├── todo-service/            # Todo CRUD microservice
│   ├── src/
│   │   ├── database/        # PostgreSQL connection
│   │   ├── models/          # Data models
│   │   ├── routes/          # API routes
│   │   └── middleware/      # Auth middleware
│   ├── Dockerfile
│   └── package.json
├── user-service/            # User auth microservice
│   ├── src/
│   │   └── routes/          # Auth routes
│   ├── Dockerfile
│   └── package.json
├── notification-service/    # Notification microservice
│   ├── Dockerfile
│   └── package.json
├── k8s-specifications/      # Kubernetes manifests
│   ├── postgres-deployment.yaml
│   ├── redis-deployment.yaml
│   ├── todo-service-deployment.yaml
│   ├── user-service-deployment.yaml
│   ├── notification-service-deployment.yaml
│   ├── api-gateway-deployment.yaml
│   ├── frontend-deployment.yaml
│   └── ingress.yaml
├── helm-charts/             # Helm charts (optional)
├── docker-compose.yml       # Local development
└── README.md               # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Security Notes

- Change default passwords in production
- Use proper secrets management
- Enable HTTPS in production
- Implement proper RBAC
- Regular security updates

## Troubleshooting

### Common Issues

1. **Pods not starting**: Check resource limits and node capacity
2. **Database connection issues**: Verify PostgreSQL service is running
3. **Image pull errors**: Ensure images are pushed to GCR
4. **Ingress not working**: Check ingress controller installation

### Debug Commands

```bash
# Describe resources
kubectl describe pod <pod-name>
kubectl describe service <service-name>

# Check resource usage
kubectl top nodes
kubectl top pods

# Events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## License

MIT License - see LICENSE file for details.

---

This todo application demonstrates microservices architecture, containerization, and Kubernetes orchestration. It's designed for learning and can be extended for production use with additional security, monitoring, and scaling features.

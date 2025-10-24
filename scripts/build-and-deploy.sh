#!/bin/bash
# Complete Build and Deploy Script for Todo Microservices
# Works for both Docker Desktop Kubernetes and GKE

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-todo-app}"
ENVIRONMENT="${ENVIRONMENT:-local}"  # local or gke
PROJECT_ID="${GCP_PROJECT_ID:-}"
REGISTRY="${REGISTRY:-localhost:5000}"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check if Kubernetes is running
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Kubernetes cluster is not accessible"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Function to clean up old Docker images
cleanup_old_images() {
    print_info "Cleaning up old Docker images..."
    
    # Remove old todo app images
    docker images | grep -E "todo-|api-gateway" | awk '{print $3}' | xargs -r docker rmi -f || true
    
    # Remove dangling images
    docker image prune -f
    
    print_success "Old images cleaned up"
}

# Function to build Docker images
build_images() {
    print_info "Building Docker images..."
    
    local services=("frontend" "api-gateway" "user-service" "todo-service" "notification-service")
    
    for service in "${services[@]}"; do
        print_info "Building $service..."
        
        cd "$service"
        
        # Build image with proper tags
        if [ "$ENVIRONMENT" == "gke" ]; then
            # Build for GKE
            docker build -t "gcr.io/${PROJECT_ID}/${service}:latest" \
                        -t "gcr.io/${PROJECT_ID}/${service}:$(git rev-parse --short HEAD)" \
                        --build-arg REACT_APP_API_URL="/api" \
                        .
        else
            # Build for local
            docker build -t "${service}:latest" \
                        -t "${service}:dev" \
                        --build-arg REACT_APP_API_URL="http://localhost:8080/api" \
                        .
        fi
        
        if [ $? -eq 0 ]; then
            print_success "$service image built successfully"
        else
            print_error "Failed to build $service"
            exit 1
        fi
        
        cd ..
    done
    
    print_success "All images built successfully"
}

# Function to push images to registry
push_images() {
    if [ "$ENVIRONMENT" != "gke" ]; then
        print_warning "Skipping image push for local environment"
        return
    fi
    
    print_info "Pushing images to GCR..."
    
    # Configure Docker for GCR
    gcloud auth configure-docker gcr.io
    
    local services=("frontend" "api-gateway" "user-service" "todo-service" "notification-service")
    
    for service in "${services[@]}"; do
        print_info "Pushing $service..."
        docker push "gcr.io/${PROJECT_ID}/${service}:latest"
        docker push "gcr.io/${PROJECT_ID}/${service}:$(git rev-parse --short HEAD)"
    done
    
    print_success "All images pushed successfully"
}

# Function to create namespace
create_namespace() {
    print_info "Creating namespace: $NAMESPACE..."
    
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace "$NAMESPACE" name="$NAMESPACE" --overwrite
    
    print_success "Namespace ready"
}

# Function to create secrets
create_secrets() {
    print_info "Creating secrets..."
    
    # Generate JWT secret if not exists
    JWT_SECRET="${JWT_SECRET:-$(openssl rand -base64 32)}"
    
    kubectl create secret generic app-secrets \
        --from-literal=JWT_SECRET="$JWT_SECRET" \
        --from-literal=DB_PASSWORD="password" \
        --from-literal=POSTGRES_PASSWORD="password" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Secrets created"
}

# Function to deploy to Kubernetes
deploy_to_kubernetes() {
    print_info "Deploying to Kubernetes..."
    
    # Deploy infrastructure (postgres, redis)
    print_info "Deploying databases..."
    kubectl apply -f k8s/simple/postgres-deployment.yaml -n "$NAMESPACE"
    kubectl apply -f k8s/simple/redis-deployment.yaml -n "$NAMESPACE"
    
    # Wait for databases
    print_info "Waiting for databases to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n "$NAMESPACE" --timeout=120s
    kubectl wait --for=condition=ready pod -l app=redis -n "$NAMESPACE" --timeout=120s
    
    # Deploy backend services
    print_info "Deploying backend services..."
    kubectl apply -f k8s/simple/user-service-deployment.yaml -n "$NAMESPACE"
    kubectl apply -f k8s/simple/todo-service-deployment.yaml -n "$NAMESPACE"
    kubectl apply -f k8s/simple/notification-service-deployment.yaml -n "$NAMESPACE"
    
    # Wait for backend services
    sleep 10
    
    # Deploy API Gateway
    print_info "Deploying API Gateway..."
    kubectl apply -f k8s/simple/api-gateway-deployment.yaml -n "$NAMESPACE"
    
    # Wait for API Gateway
    sleep 5
    
    # Deploy Frontend
    print_info "Deploying Frontend..."
    kubectl apply -f k8s/simple/frontend-deployment.yaml -n "$NAMESPACE"
    
    print_success "All services deployed"
}

# Function to check deployment status
check_deployment() {
    print_info "Checking deployment status..."
    
    kubectl get pods -n "$NAMESPACE"
    kubectl get services -n "$NAMESPACE"
    
    print_info "Waiting for all pods to be ready..."
    kubectl wait --for=condition=ready pod --all -n "$NAMESPACE" --timeout=300s
    
    print_success "All pods are ready"
}

# Function to setup port forwarding
setup_port_forward() {
    if [ "$ENVIRONMENT" != "local" ]; then
        print_warning "Port forwarding is only for local environment"
        return
    fi
    
    print_info "Setting up port forwarding..."
    print_info "Run these commands in separate terminals:"
    print_info "  kubectl port-forward svc/frontend-service 3000:80 -n $NAMESPACE"
    print_info "  kubectl port-forward svc/api-gateway-service 8080:8080 -n $NAMESPACE"
}

# Function to display access information
display_access_info() {
    print_success "Deployment completed successfully!"
    echo ""
    print_info "Access Information:"
    
    if [ "$ENVIRONMENT" == "local" ]; then
        echo "  Frontend: http://localhost:3000 (after port-forward)"
        echo "  API Gateway: http://localhost:8080 (after port-forward)"
        echo ""
        print_info "Setup port forwarding:"
        echo "  kubectl port-forward svc/frontend-service 3000:80 -n $NAMESPACE &"
        echo "  kubectl port-forward svc/api-gateway-service 8080:8080 -n $NAMESPACE &"
    else
        INGRESS_IP=$(kubectl get ingress todo-ingress -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        echo "  Application: http://$INGRESS_IP"
    fi
    
    echo ""
    print_info "Useful commands:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl logs -f <pod-name> -n $NAMESPACE"
    echo "  kubectl describe pod <pod-name> -n $NAMESPACE"
}

# Main execution
main() {
    print_info "Starting deployment process..."
    print_info "Environment: $ENVIRONMENT"
    print_info "Namespace: $NAMESPACE"
    
    check_prerequisites
    cleanup_old_images
    build_images
    push_images
    create_namespace
    create_secrets
    deploy_to_kubernetes
    check_deployment
    setup_port_forward
    display_access_info
}

# Run main function
main "$@"

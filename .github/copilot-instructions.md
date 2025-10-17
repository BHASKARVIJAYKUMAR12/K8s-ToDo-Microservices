# Todo Application Microservices Project

## Project Overview

This is a comprehensive todo application built with microservices architecture for learning Kubernetes deployment, similar to the voting app demo but with modern TypeScript stack.

## Architecture

- **Frontend Service**: React + TypeScript UI
- **API Gateway**: Node.js + TypeScript request router
- **Todo Service**: Node.js + TypeScript CRUD operations
- **User Service**: Node.js + TypeScript authentication
- **Notification Service**: Node.js + TypeScript notifications
- **PostgreSQL**: Database for persistent storage
- **Redis**: Caching and message queue

## Development Guidelines

- Use TypeScript for all services
- Follow microservices best practices
- Include proper error handling and logging
- Use environment variables for configuration
- Include health check endpoints
- Follow RESTful API conventions

## Deployment

- Docker containers for each service
- Kubernetes manifests for GKE deployment
- Helm charts for easy deployment
- Ingress for external access

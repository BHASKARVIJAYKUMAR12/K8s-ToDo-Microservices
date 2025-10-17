#!/bin/bash

# 🚀 Start All Services in Development Mode

echo "🔥 Starting Todo App in Development Mode..."
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Start databases in Docker (if not running)
echo "🐳 Starting databases in Docker..."
docker-compose up -d postgres redis

# Wait for databases to be ready
echo "⏳ Waiting for databases to be ready..."
sleep 5

# Function to start a service in a new terminal
start_service() {
    local service_name=$1
    local port=$2
    local path=$3
    
    echo "🚀 Starting $service_name on port $port..."
    
    # Start in new PowerShell window
    powershell -Command "Start-Process powershell -ArgumentList '-NoExit', '-Command', 'cd $path; npm install; npm run dev'"
}

# Start all services
start_service "API Gateway" "8080" "api-gateway"
start_service "User Service" "3002" "user-service"  
start_service "Todo Service" "3001" "todo-service"
start_service "Notification Service" "3003" "notification-service"
start_service "Frontend" "3000" "frontend"

echo ""
echo "✅ All services are starting..."
echo ""
echo "🌐 Your application will be available at:"
echo "   Frontend: http://localhost:3000"
echo "   API Gateway: http://localhost:8080"
echo ""
echo "📊 Service URLs:"
echo "   User Service: http://localhost:3002"
echo "   Todo Service: http://localhost:3001" 
echo "   Notification Service: http://localhost:3003"
echo ""
echo "🛑 To stop all services:"
echo "   - Close all PowerShell windows"
echo "   - Run: docker-compose down"
echo ""
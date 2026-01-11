#!/bin/bash

# AIVONITY Kubernetes Deployment Script
set -e

echo "🚀 Starting AIVONITY Kubernetes Deployment"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Not connected to a Kubernetes cluster"
    exit 1
fi

echo "✅ Connected to Kubernetes cluster"

# Create namespace
echo "📁 Creating namespace..."
kubectl apply -f namespace.yaml

# Apply secrets (make sure to update with real values)
echo "🔐 Applying secrets..."
kubectl apply -f secrets.yaml

# Apply config maps
echo "⚙️ Applying configuration..."
kubectl apply -f configmap.yaml

# Deploy PostgreSQL
echo "🐘 Deploying PostgreSQL with TimescaleDB..."
kubectl apply -f postgres-deployment.yaml

# Deploy Redis
echo "🔴 Deploying Redis..."
kubectl apply -f redis-deployment.yaml

# Wait for databases to be ready
echo "⏳ Waiting for databases to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment -n aivonity
kubectl wait --for=condition=available --timeout=300s deployment/redis-deployment -n aivonity

# Deploy backend application
echo "🖥️ Deploying AIVONITY Backend..."
kubectl apply -f backend-deployment.yaml

# Deploy Nginx load balancer
echo "🌐 Deploying Nginx load balancer..."
kubectl apply -f nginx-deployment.yaml

# Apply ingress
echo "🚪 Setting up ingress..."
kubectl apply -f ingress.yaml

# Apply horizontal pod autoscalers
echo "📈 Setting up auto-scaling..."
kubectl apply -f hpa.yaml

# Deploy monitoring stack
echo "📊 Deploying monitoring stack..."
kubectl apply -f monitoring.yaml

# Wait for all deployments to be ready
echo "⏳ Waiting for all deployments to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/aivonity-backend-deployment -n aivonity
kubectl wait --for=condition=available --timeout=300s deployment/nginx-deployment -n aivonity
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-deployment -n aivonity
kubectl wait --for=condition=available --timeout=300s deployment/grafana-deployment -n aivonity

echo "✅ AIVONITY deployment completed successfully!"

# Display service information
echo ""
echo "📋 Service Information:"
kubectl get services -n aivonity

echo ""
echo "🎯 Pod Status:"
kubectl get pods -n aivonity

echo ""
echo "🌐 Access Information:"
echo "- API: http://$(kubectl get service nginx-service -n aivonity -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "- Grafana: http://$(kubectl get service grafana-service -n aivonity -o jsonpath='{.spec.clusterIP}'):3000"
echo "- Prometheus: http://$(kubectl get service prometheus-service -n aivonity -o jsonpath='{.spec.clusterIP}'):9090"

echo ""
echo "🔧 Useful commands:"
echo "- View logs: kubectl logs -f deployment/aivonity-backend-deployment -n aivonity"
echo "- Scale backend: kubectl scale deployment aivonity-backend-deployment --replicas=5 -n aivonity"
echo "- Port forward API: kubectl port-forward service/nginx-service 8080:80 -n aivonity"
echo "- Port forward Grafana: kubectl port-forward service/grafana-service 3000:3000 -n aivonity"
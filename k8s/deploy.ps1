# AIVONITY Kubernetes Deployment Script (PowerShell)
param(
    [switch]$SkipConfirmation
)

Write-Host "🚀 Starting AIVONITY Kubernetes Deployment" -ForegroundColor Green

# Check if kubectl is available
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if we're connected to a cluster
try {
    kubectl cluster-info | Out-Null
    Write-Host "✅ Connected to Kubernetes cluster" -ForegroundColor Green
} catch {
    Write-Host "❌ Not connected to a Kubernetes cluster" -ForegroundColor Red
    exit 1
}

# Create namespace
Write-Host "📁 Creating namespace..." -ForegroundColor Yellow
kubectl apply -f namespace.yaml

# Apply secrets (make sure to update with real values)
Write-Host "🔐 Applying secrets..." -ForegroundColor Yellow
kubectl apply -f secrets.yaml

# Apply config maps
Write-Host "⚙️ Applying configuration..." -ForegroundColor Yellow
kubectl apply -f configmap.yaml

# Deploy PostgreSQL
Write-Host "🐘 Deploying PostgreSQL with TimescaleDB..." -ForegroundColor Yellow
kubectl apply -f postgres-deployment.yaml

# Deploy Redis
Write-Host "🔴 Deploying Redis..." -ForegroundColor Yellow
kubectl apply -f redis-deployment.yaml

# Wait for databases to be ready
Write-Host "⏳ Waiting for databases to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment -n aivonity
kubectl wait --for=condition=available --timeout=300s deployment/redis-deployment -n aivonity

# Deploy backend application
Write-Host "🖥️ Deploying AIVONITY Backend..." -ForegroundColor Yellow
kubectl apply -f backend-deployment.yaml

# Deploy Nginx load balancer
Write-Host "🌐 Deploying Nginx load balancer..." -ForegroundColor Yellow
kubectl apply -f nginx-deployment.yaml

# Apply ingress
Write-Host "🚪 Setting up ingress..." -ForegroundColor Yellow
kubectl apply -f ingress.yaml

# Apply horizontal pod autoscalers
Write-Host "📈 Setting up auto-scaling..." -ForegroundColor Yellow
kubectl apply -f hpa.yaml

# Deploy monitoring stack
Write-Host "📊 Deploying monitoring stack..." -ForegroundColor Yellow
kubectl apply -f monitoring.yaml

# Wait for all deployments to be ready
Write-Host "⏳ Waiting for all deployments to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=600s deployment/aivonity-backend-deployment -n aivonity
kubectl wait --for=condition=available --timeout=300s deployment/nginx-deployment -n aivonity
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-deployment -n aivonity
kubectl wait --for=condition=available --timeout=300s deployment/grafana-deployment -n aivonity

Write-Host "✅ AIVONITY deployment completed successfully!" -ForegroundColor Green

# Display service information
Write-Host ""
Write-Host "📋 Service Information:" -ForegroundColor Cyan
kubectl get services -n aivonity

Write-Host ""
Write-Host "🎯 Pod Status:" -ForegroundColor Cyan
kubectl get pods -n aivonity

Write-Host ""
Write-Host "🌐 Access Information:" -ForegroundColor Cyan
$nginxIP = kubectl get service nginx-service -n aivonity -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$grafanaIP = kubectl get service grafana-service -n aivonity -o jsonpath='{.spec.clusterIP}'
$prometheusIP = kubectl get service prometheus-service -n aivonity -o jsonpath='{.spec.clusterIP}'

Write-Host "- API: http://$nginxIP" -ForegroundColor White
Write-Host "- Grafana: http://$grafanaIP:3000" -ForegroundColor White
Write-Host "- Prometheus: http://$prometheusIP:9090" -ForegroundColor White

Write-Host ""
Write-Host "🔧 Useful commands:" -ForegroundColor Cyan
Write-Host "- View logs: kubectl logs -f deployment/aivonity-backend-deployment -n aivonity" -ForegroundColor White
Write-Host "- Scale backend: kubectl scale deployment aivonity-backend-deployment --replicas=5 -n aivonity" -ForegroundColor White
Write-Host "- Port forward API: kubectl port-forward service/nginx-service 8080:80 -n aivonity" -ForegroundColor White
Write-Host "- Port forward Grafana: kubectl port-forward service/grafana-service 3000:3000 -n aivonity" -ForegroundColor White
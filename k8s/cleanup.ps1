# AIVONITY Kubernetes Cleanup Script (PowerShell)
param(
    [switch]$Force
)

Write-Host "🧹 Starting AIVONITY Kubernetes Cleanup" -ForegroundColor Yellow

# Check if kubectl is available
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Confirm deletion unless -Force is used
if (-not $Force) {
    $confirmation = Read-Host "⚠️ This will delete all AIVONITY resources. Are you sure? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "❌ Cleanup cancelled" -ForegroundColor Red
        exit 1
    }
}

Write-Host "🗑️ Deleting AIVONITY resources..." -ForegroundColor Yellow

# Delete in reverse order of dependencies
kubectl delete -f monitoring.yaml --ignore-not-found=true
kubectl delete -f hpa.yaml --ignore-not-found=true
kubectl delete -f ingress.yaml --ignore-not-found=true
kubectl delete -f nginx-deployment.yaml --ignore-not-found=true
kubectl delete -f backend-deployment.yaml --ignore-not-found=true
kubectl delete -f redis-deployment.yaml --ignore-not-found=true
kubectl delete -f postgres-deployment.yaml --ignore-not-found=true
kubectl delete -f configmap.yaml --ignore-not-found=true
kubectl delete -f secrets.yaml --ignore-not-found=true

# Delete persistent volume claims
Write-Host "💾 Deleting persistent volumes..." -ForegroundColor Yellow
kubectl delete pvc --all -n aivonity --ignore-not-found=true

# Delete namespace (this will delete any remaining resources)
Write-Host "📁 Deleting namespace..." -ForegroundColor Yellow
kubectl delete -f namespace.yaml --ignore-not-found=true

Write-Host "✅ AIVONITY cleanup completed successfully!" -ForegroundColor Green
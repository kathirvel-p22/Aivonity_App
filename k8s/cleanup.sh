#!/bin/bash

# AIVONITY Kubernetes Cleanup Script
set -e

echo "🧹 Starting AIVONITY Kubernetes Cleanup"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Confirm deletion
read -p "⚠️ This will delete all AIVONITY resources. Are you sure? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo "🗑️ Deleting AIVONITY resources..."

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
echo "💾 Deleting persistent volumes..."
kubectl delete pvc --all -n aivonity --ignore-not-found=true

# Delete namespace (this will delete any remaining resources)
echo "📁 Deleting namespace..."
kubectl delete -f namespace.yaml --ignore-not-found=true

echo "✅ AIVONITY cleanup completed successfully!"
#!/usr/bin/env bash
set -euo pipefail

# Delete only Kubernetes Dashboard resources.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is not installed. Please install kubectl first."
  exit 1
fi

echo "Deleting Kubernetes Dashboard resources..."
kubectl delete -f dashboard/dashboard-service.yaml --ignore-not-found=true
kubectl delete -f dashboard/dashboard-deployment.yaml --ignore-not-found=true
kubectl delete -f dashboard/dashboard-configmap.yaml --ignore-not-found=true
kubectl delete -f dashboard/dashboard-secret.yaml --ignore-not-found=true
kubectl delete -f dashboard/dashboard-rbac.yaml --ignore-not-found=true
kubectl delete -f dashboard/dashboard-serviceaccount.yaml --ignore-not-found=true
kubectl delete -f dashboard/dashboard-namespace.yaml --ignore-not-found=true

if [ -f "dashboard-token.txt" ]; then
  rm dashboard-token.txt
fi

echo "Dashboard resources removed."

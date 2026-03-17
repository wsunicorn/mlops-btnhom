#!/usr/bin/env bash
set -euo pipefail

# Deploy only Kubernetes Dashboard resources.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is not installed. Please install kubectl first."
  exit 1
fi

echo "Deploying Kubernetes Dashboard resources..."
kubectl apply -f dashboard/dashboard-namespace.yaml
kubectl apply -f dashboard/dashboard-serviceaccount.yaml
kubectl apply -f dashboard/dashboard-rbac.yaml
kubectl apply -f dashboard/dashboard-secret.yaml
kubectl apply -f dashboard/dashboard-configmap.yaml
kubectl apply -f dashboard/dashboard-deployment.yaml
kubectl apply -f dashboard/dashboard-service.yaml

echo "Waiting for dashboard pod to become ready..."
kubectl wait --for=condition=ready pod -l k8s-app=kubernetes-dashboard -n kubernetes-dashboard --timeout=120s

echo "Dashboard deployed successfully."
echo "Run ./get-dashboard-token.sh to retrieve login token."

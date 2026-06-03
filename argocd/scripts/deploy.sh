#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-argocd}"
RELEASE_NAME="${RELEASE_NAME:-argocd}"
VALUES_PATH="$REPO_ROOT/argocd/manifests/values.yaml"

helm repo add argo "https://argoproj.github.io/argo-helm" >/dev/null 2>&1 || true
helm repo update >/dev/null

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

helm upgrade --install "$RELEASE_NAME" argo/argo-cd \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout 20m \
  -f "$VALUES_PATH"

kubectl get pods,svc -n "$NAMESPACE"

echo "Initial admin password:"
kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode
echo
echo "Run: ./argocd/scripts/port-forward.sh"

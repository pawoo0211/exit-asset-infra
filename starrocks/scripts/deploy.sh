#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-starrocks}"

helm repo add starrocks "https://starrocks.github.io/starrocks-kubernetes-operator" >/dev/null 2>&1 || true
helm repo update >/dev/null

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

helm upgrade --install starrocks-operator starrocks/operator \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout 15m

helm upgrade --install starrocks-local starrocks/starrocks \
  --namespace "$NAMESPACE" \
  --wait \
  --timeout 20m \
  -f "$REPO_ROOT/starrocks/manifests/values.yaml"

kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./starrocks/scripts/port-forward-fe.sh"

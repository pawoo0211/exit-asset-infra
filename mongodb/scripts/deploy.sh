#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-mongodb}"
MANIFEST_PATH="$REPO_ROOT/mongodb/manifests/mongodb.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/mongodb -n "$NAMESPACE" --timeout=300s
kubectl get pods,pvc,svc -n "$NAMESPACE"

echo "Run: ./mongodb/scripts/port-forward.sh"

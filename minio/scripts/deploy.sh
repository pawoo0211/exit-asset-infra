#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-minio}"
MANIFEST_PATH="$REPO_ROOT/minio/manifests/minio.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/minio -n "$NAMESPACE" --timeout=300s
kubectl get pods,pvc,svc -n "$NAMESPACE"

echo "Run: ./minio/scripts/port-forward.sh"

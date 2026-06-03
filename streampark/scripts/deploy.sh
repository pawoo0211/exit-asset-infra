#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-streampark}"
MANIFEST_PATH="$REPO_ROOT/streampark/manifests/streampark.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/streampark -n "$NAMESPACE" --timeout=600s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./streampark/scripts/port-forward.sh"

#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-iceberg}"
MANIFEST_PATH="$REPO_ROOT/iceberg/manifests/nessie.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/nessie -n "$NAMESPACE" --timeout=300s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./iceberg/scripts/port-forward.sh"

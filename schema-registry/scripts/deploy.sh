#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-schema-registry}"
MANIFEST_PATH="$REPO_ROOT/schema-registry/manifests/schema-registry.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/schema-registry -n "$NAMESPACE" --timeout=300s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./schema-registry/scripts/port-forward.sh"

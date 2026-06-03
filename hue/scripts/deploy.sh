#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-hue}"
MANIFEST_PATH="$REPO_ROOT/hue/manifests/hue.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/hue -n "$NAMESPACE" --timeout=300s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./hue/scripts/port-forward.sh"

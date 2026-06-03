#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-loki}"
MANIFEST_PATH="$REPO_ROOT/loki/manifests/loki.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/loki -n "$NAMESPACE" --timeout=600s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./loki/scripts/port-forward.sh"

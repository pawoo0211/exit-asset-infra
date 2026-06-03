#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-kafka-connect}"
MANIFEST_PATH="$REPO_ROOT/kafka-connect/manifests/kafka-connect.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/kafka-connect -n "$NAMESPACE" --timeout=300s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./kafka-connect/scripts/port-forward.sh"

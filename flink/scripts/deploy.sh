#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-flink}"
MANIFEST_PATH="$REPO_ROOT/flink/manifests/flink.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/flink-jobmanager -n "$NAMESPACE" --timeout=600s
kubectl rollout status deployment/flink-taskmanager -n "$NAMESPACE" --timeout=600s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./flink/scripts/port-forward.sh"

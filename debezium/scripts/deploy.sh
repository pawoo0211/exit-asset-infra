#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-debezium}"
MANIFEST_PATH="$REPO_ROOT/debezium/manifests/debezium-connect.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/debezium-connect -n "$NAMESPACE" --timeout=300s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./debezium/scripts/port-forward.sh"

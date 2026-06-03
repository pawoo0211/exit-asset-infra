#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-clickhouse}"
MANIFEST_PATH="$REPO_ROOT/clickhouse/manifests/clickhouse.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl rollout status deployment/clickhouse -n "$NAMESPACE" --timeout=600s
kubectl rollout status deployment/clickhouse-web -n "$NAMESPACE" --timeout=600s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./clickhouse/scripts/port-forward.sh"

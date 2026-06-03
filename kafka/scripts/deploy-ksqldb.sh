#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-kafka}"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$REPO_ROOT/kafka/manifests/ksqldb.yaml"
kubectl -n "$NAMESPACE" rollout status deployment/ksqldb-server --timeout=180s
kubectl -n "$NAMESPACE" get pods,svc | grep -E "ksqldb-server|NAME"

echo "Run: ./kafka/scripts/port-forward-ksqldb.sh"

#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-paimon}"
MANIFEST_PATH="$REPO_ROOT/paimon/manifests/catalog-config.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$MANIFEST_PATH"
kubectl get configmaps -n "$NAMESPACE"

echo "Paimon/Iceberg catalog configmaps created in namespace $NAMESPACE"

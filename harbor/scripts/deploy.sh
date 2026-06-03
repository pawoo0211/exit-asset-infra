#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-harbor}"
RELEASE_NAME="${RELEASE_NAME:-harbor}"
VALUES_PATH="$REPO_ROOT/harbor/manifests/values.yaml"

helm repo add harbor "https://helm.goharbor.io" >/dev/null 2>&1 || true
helm repo update >/dev/null

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

helm upgrade --install "$RELEASE_NAME" harbor/harbor \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout 20m \
  -f "$VALUES_PATH"

kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./harbor/scripts/port-forward.sh"

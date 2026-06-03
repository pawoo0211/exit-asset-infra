#!/usr/bin/env bash

# Fix stuck kafka-topics Helm release (pending state)
# Usage: ./scripts/fix-kafka-topics-helm.sh

set -euo pipefail

RELEASE_NAME="kafka-topics-local"
NAMESPACE="kafka"

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Kubernetes cluster is unreachable. Start Colima first: ./scripts/setup-k3s-colima.sh"
  exit 1
fi

echo "Checking Helm release status..."
helm -n "$NAMESPACE" list --all 2>/dev/null | grep "$RELEASE_NAME" || echo "Release not found"

echo "Attempting to clear pending state..."

# Try rollback to last deployed revision
last_rev=$(helm -n "$NAMESPACE" history "$RELEASE_NAME" 2>/dev/null | grep -E "^\s*[0-9]+\s+deployed" | tail -1 | awk '{print $1}' || echo "")
if [[ -n "$last_rev" ]] && [[ "$last_rev" =~ ^[0-9]+$ ]]; then
  echo "Rolling back to revision $last_rev..."
  helm rollback "$RELEASE_NAME" "$last_rev" -n "$NAMESPACE" || true
  sleep 3
fi

# Uninstall if exists
echo "Uninstalling release..."
helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" 2>/dev/null || true

# Delete Helm secrets that might be stuck
echo "Cleaning up Helm secrets..."
kubectl -n "$NAMESPACE" delete secret -l "owner=helm,name=$RELEASE_NAME" 2>/dev/null || true
for secret in $(kubectl -n "$NAMESPACE" get secret -o name 2>/dev/null | grep "sh.helm.release.v1.$RELEASE_NAME" || true); do
  kubectl -n "$NAMESPACE" delete "$secret" 2>/dev/null || true
done

echo "Done. You can now run: ./scripts/deploy-all.sh"

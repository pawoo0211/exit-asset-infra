#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[1/4] Deploying Argo CD..."
"$REPO_ROOT/scripts/deploy.sh" argocd

echo "[2/4] Applying Argo CD AppProject + child Applications..."
kubectl -n argocd apply -f "$REPO_ROOT/argocd/apps/children/project.yaml"
kubectl -n argocd apply -f "$REPO_ROOT/argocd/apps/children/apps.yaml"

echo "[3/4] Applying root app-of-apps..."
kubectl -n argocd apply -f "$REPO_ROOT/argocd/apps/root.yaml"

echo "[4/4] Waiting for root app creation..."
for i in 1 2 3 4 5 6; do
  if kubectl -n argocd get application infra-local-root >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

kubectl -n argocd get applications

echo
echo "Argo CD GitOps sync mode is enabled."
echo "Use: kubectl -n argocd get applications"
echo "Then refresh UI/port-forward with: ./scripts/start-port-forwards.sh"

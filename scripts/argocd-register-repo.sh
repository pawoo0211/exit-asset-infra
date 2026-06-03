#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/pawoo0211/exit-asset-infra.git}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
SECRET_NAME="${SECRET_NAME:-repo-exit-asset-infra}"
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

if [[ -z "$GITHUB_USERNAME" || -z "$GITHUB_TOKEN" ]]; then
  echo "Set GITHUB_USERNAME and GITHUB_TOKEN first."
  echo "Example: GITHUB_USERNAME=your-id GITHUB_TOKEN=ghp_xxx ./scripts/argocd-register-repo.sh"
  exit 1
fi

kubectl -n "$ARGOCD_NAMESPACE" apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: $REPO_URL
  username: $GITHUB_USERNAME
  password: $GITHUB_TOKEN
EOF

echo "Repository credential registered in namespace $ARGOCD_NAMESPACE"

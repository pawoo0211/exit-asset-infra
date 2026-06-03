#!/usr/bin/env bash

set -euo pipefail

export GODEBUG="${GODEBUG:-http2client=0}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-spark}"
APP_MANIFEST="$REPO_ROOT/spark/manifests/spark-pi-hdfs.yaml"

# Best-effort: ensure Spark eventlog directory exists on the macOS-local HDFS.
if command -v hdfs >/dev/null 2>&1; then
  hdfs dfs -mkdir -p /spark-history >/dev/null 2>&1 || true
  hdfs dfs -chmod 777 /spark-history >/dev/null 2>&1 || true
else
  echo "[WARN] 'hdfs' command not found on host; skipping HDFS directory preparation."
fi

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" delete sparkapplication spark-pi-hdfs --ignore-not-found=true >/dev/null 2>&1 || true
kubectl -n "$NAMESPACE" apply -f "$APP_MANIFEST"
kubectl -n "$NAMESPACE" get sparkapplication spark-pi-hdfs -w

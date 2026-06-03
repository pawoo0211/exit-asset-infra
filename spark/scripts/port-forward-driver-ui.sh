#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-spark}"
APP_NAME="${1:-spark-pi-hdfs}"
LOCAL_PORT="${2:-4040}"
SERVICE="${APP_NAME}-ui-svc"

if ! kubectl -n "$NAMESPACE" get svc "$SERVICE" >/dev/null 2>&1; then
  echo "Service $SERVICE not found in namespace $NAMESPACE"
  echo "Wait until SparkApplication driver is running."
  exit 1
fi

echo "Spark Driver UI -> http://localhost:${LOCAL_PORT}"
kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "${LOCAL_PORT}:4040"

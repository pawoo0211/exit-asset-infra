#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-minio}"
SERVICE="${SERVICE:-minio}"
API_LOCAL_PORT="${1:-19000}"
CONSOLE_LOCAL_PORT="${2:-19001}"
MODE="${3:-foreground}"
PID_FILE="/tmp/minio-port-forward-${API_LOCAL_PORT}-${CONSOLE_LOCAL_PORT}.pid"
LOG_FILE="/tmp/minio-port-forward-${API_LOCAL_PORT}-${CONSOLE_LOCAL_PORT}.log"

if ! kubectl get svc "$SERVICE" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Service $SERVICE not found in namespace $NAMESPACE"
  echo "Run: ./minio/scripts/deploy.sh"
  exit 1
fi

if lsof -nP -iTCP:"$API_LOCAL_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port $API_LOCAL_PORT is already in use."
  echo "Try: ./minio/scripts/port-forward.sh 19002 19003"
  exit 1
fi

if lsof -nP -iTCP:"$CONSOLE_LOCAL_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port $CONSOLE_LOCAL_PORT is already in use."
  echo "Try: ./minio/scripts/port-forward.sh 19002 19003"
  exit 1
fi

if [[ "$MODE" == "--background" ]]; then
  nohup kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$API_LOCAL_PORT":9000 "$CONSOLE_LOCAL_PORT":9001 >"$LOG_FILE" 2>&1 &
  PF_PID=$!
  echo "$PF_PID" > "$PID_FILE"
  sleep 2
  if kill -0 "$PF_PID" >/dev/null 2>&1; then
    echo "MinIO API -> http://localhost:$API_LOCAL_PORT"
    echo "MinIO Console -> http://localhost:$CONSOLE_LOCAL_PORT"
    echo "Port-forward PID: $PF_PID"
    echo "Log: $LOG_FILE"
    exit 0
  fi
  echo "Failed to start MinIO port-forward. Check log: $LOG_FILE"
  exit 1
fi

echo "MinIO API -> http://localhost:$API_LOCAL_PORT"
echo "MinIO Console -> http://localhost:$CONSOLE_LOCAL_PORT"
kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$API_LOCAL_PORT":9000 "$CONSOLE_LOCAL_PORT":9001

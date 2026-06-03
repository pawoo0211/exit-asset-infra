#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-starrocks}"
SERVICE="${SERVICE:-kube-starrocks-fe-service}"
LOCAL_PORT="${1:-19030}"
TARGET_PORT="${TARGET_PORT:-9030}"
MODE="${2:-foreground}"
PID_FILE="/tmp/starrocks-fe-port-forward-${LOCAL_PORT}.pid"
LOG_FILE="/tmp/starrocks-fe-port-forward-${LOCAL_PORT}.log"

if ! kubectl get svc "$SERVICE" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Service $SERVICE not found in namespace $NAMESPACE"
  echo "Run: ./starrocks/scripts/deploy.sh"
  exit 1
fi

if lsof -nP -iTCP:"$LOCAL_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "StarRocks FE port-forward already running on localhost:$LOCAL_PORT"
    echo "PID: $(cat "$PID_FILE")"
    exit 0
  fi
  echo "Port $LOCAL_PORT is already in use."
  echo "Try: ./starrocks/scripts/port-forward-fe.sh 19031"
  exit 1
fi

if [[ "$MODE" == "--background" ]]; then
  nohup kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$LOCAL_PORT":"$TARGET_PORT" >"$LOG_FILE" 2>&1 &
  PF_PID=$!
  echo "$PF_PID" > "$PID_FILE"
  sleep 2
  if kill -0 "$PF_PID" >/dev/null 2>&1; then
    echo "StarRocks FE(MySQL protocol) -> localhost:$LOCAL_PORT"
    echo "Port-forward PID: $PF_PID"
    echo "Log: $LOG_FILE"
    exit 0
  fi
  echo "Failed to start StarRocks port-forward. Check log: $LOG_FILE"
  exit 1
fi

echo "StarRocks FE(MySQL protocol) -> localhost:$LOCAL_PORT"
kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$LOCAL_PORT":"$TARGET_PORT"

#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-debezium}"
SERVICE="${SERVICE:-debezium-connect}"
LOCAL_PORT="${1:-18087}"
TARGET_PORT="${TARGET_PORT:-8083}"
MODE="${2:-foreground}"
PID_FILE="/tmp/debezium-port-forward-${LOCAL_PORT}.pid"
LOG_FILE="/tmp/debezium-port-forward-${LOCAL_PORT}.log"

if ! kubectl get svc "$SERVICE" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Service $SERVICE not found in namespace $NAMESPACE"
  echo "Run: ./debezium/scripts/deploy.sh"
  exit 1
fi

if lsof -nP -iTCP:"$LOCAL_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "Debezium Connect port-forward already running on http://localhost:$LOCAL_PORT"
    echo "PID: $(cat "$PID_FILE")"
    exit 0
  fi
  echo "Port $LOCAL_PORT is already in use."
  echo "Try: ./debezium/scripts/port-forward.sh 18097"
  exit 1
fi

if [[ "$MODE" == "--background" ]]; then
  nohup kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$LOCAL_PORT":"$TARGET_PORT" >"$LOG_FILE" 2>&1 &
  PF_PID=$!
  echo "$PF_PID" > "$PID_FILE"
  sleep 2
  if kill -0 "$PF_PID" >/dev/null 2>&1; then
    echo "Debezium Connect -> http://localhost:$LOCAL_PORT"
    echo "Port-forward PID: $PF_PID"
    echo "Log: $LOG_FILE"
    exit 0
  fi
  echo "Failed to start Debezium Connect port-forward. Check log: $LOG_FILE"
  exit 1
fi

echo "Debezium Connect -> http://localhost:$LOCAL_PORT"
kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$LOCAL_PORT":"$TARGET_PORT"

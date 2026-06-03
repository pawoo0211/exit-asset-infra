#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-kafka}"
SERVICE="${SERVICE:-kafka-ui}"
LOCAL_PORT="${1:-18080}"
TARGET_PORT="${TARGET_PORT:-8080}"
MODE="${2:-foreground}"
PID_FILE="/tmp/kafka-ui-port-forward-${LOCAL_PORT}.pid"
LOG_FILE="/tmp/kafka-ui-port-forward-${LOCAL_PORT}.log"

if ! kubectl get svc "$SERVICE" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Service $SERVICE not found in namespace $NAMESPACE"
  echo "Run: ./kafka/scripts/deploy-kafka-ui.sh"
  exit 1
fi

if lsof -nP -iTCP:"$LOCAL_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "Kafka UI port-forward already running on http://localhost:$LOCAL_PORT/ui"
    echo "PID: $(cat "$PID_FILE")"
    exit 0
  fi
  echo "Port $LOCAL_PORT is already in use."
  echo "Try: ./kafka/scripts/port-forward-kafka-ui.sh 18081  # then open http://localhost:18081/ui"
  exit 1
fi

if [[ "$MODE" == "--background" ]]; then
  nohup kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$LOCAL_PORT":"$TARGET_PORT" >"$LOG_FILE" 2>&1 &
  PF_PID=$!
  echo "$PF_PID" > "$PID_FILE"
  sleep 2
  if kill -0 "$PF_PID" >/dev/null 2>&1; then
    echo "Kafka UI -> http://localhost:$LOCAL_PORT/ui"
    echo "Port-forward PID: $PF_PID"
    echo "Log: $LOG_FILE"
    exit 0
  fi
  echo "Failed to start Kafka UI port-forward. Check log: $LOG_FILE"
  exit 1
fi

echo "Kafka UI -> http://localhost:$LOCAL_PORT/ui"
kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$LOCAL_PORT":"$TARGET_PORT"

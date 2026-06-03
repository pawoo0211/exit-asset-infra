#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-clickhouse}"
LOCAL_WEB_PORT="${1:-18102}"
LOCAL_HTTP_PORT="${2:-18101}"
MODE="${3:-foreground}"
PID_FILE="/tmp/clickhouse-port-forward-${LOCAL_WEB_PORT}-${LOCAL_HTTP_PORT}.pid"
LOG_FILE="/tmp/clickhouse-port-forward-${LOCAL_WEB_PORT}-${LOCAL_HTTP_PORT}.log"
WEB_LOG_FILE="/tmp/clickhouse-web-port-forward-${LOCAL_WEB_PORT}.log"
HTTP_LOG_FILE="/tmp/clickhouse-http-port-forward-${LOCAL_HTTP_PORT}.log"

if ! kubectl get svc clickhouse-web -n "$NAMESPACE" >/dev/null 2>&1 || ! kubectl get svc clickhouse -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "ClickHouse services not found in namespace $NAMESPACE"
  echo "Run: ./clickhouse/scripts/deploy.sh"
  exit 1
fi

if lsof -nP -iTCP:"$LOCAL_WEB_PORT" -sTCP:LISTEN >/dev/null 2>&1 || lsof -nP -iTCP:"$LOCAL_HTTP_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "ClickHouse port-forward already running on http://localhost:$LOCAL_WEB_PORT and localhost:$LOCAL_HTTP_PORT"
    echo "PID: $(cat "$PID_FILE")"
    exit 0
  fi
  echo "Port $LOCAL_WEB_PORT or $LOCAL_HTTP_PORT is already in use."
  exit 1
fi

if [[ "$MODE" == "--background" ]]; then
  nohup kubectl -n "$NAMESPACE" port-forward svc/clickhouse-web "$LOCAL_WEB_PORT":80 >"$WEB_LOG_FILE" 2>&1 &
  WEB_PF_PID=$!
  nohup kubectl -n "$NAMESPACE" port-forward svc/clickhouse "$LOCAL_HTTP_PORT":8123 >"$HTTP_LOG_FILE" 2>&1 &
  HTTP_PF_PID=$!
  echo "$WEB_PF_PID $HTTP_PF_PID" > "$PID_FILE"
  sleep 2
  if kill -0 "$WEB_PF_PID" >/dev/null 2>&1 && kill -0 "$HTTP_PF_PID" >/dev/null 2>&1; then
    echo "ClickHouse Web -> http://localhost:$LOCAL_WEB_PORT"
    echo "ClickHouse HTTP -> http://localhost:$LOCAL_HTTP_PORT"
    echo "Port-forward PID (web/http): $WEB_PF_PID/$HTTP_PF_PID"
    echo "Logs: $WEB_LOG_FILE , $HTTP_LOG_FILE"
    exit 0
  fi
  echo "Failed to start ClickHouse port-forward. Check logs in /tmp"
  exit 1
fi

echo "ClickHouse Web -> http://localhost:$LOCAL_WEB_PORT"
echo "ClickHouse HTTP -> http://localhost:$LOCAL_HTTP_PORT"
kubectl -n "$NAMESPACE" port-forward svc/clickhouse-web "$LOCAL_WEB_PORT":80

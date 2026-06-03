#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="/tmp/infra-port-forward-watchdog.pid"
LOG_FILE="/tmp/infra-port-forward-watchdog.log"
INTERVAL="${INTERVAL_SECONDS:-30}"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-infra-local}"

start_watchdog() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "Watchdog already running (PID: $(cat "$PID_FILE"))."
    return 0
  fi

  REPO_ROOT_ENV="$REPO_ROOT" nohup bash -lc '
    set -euo pipefail
    REPO_ROOT="${REPO_ROOT_ENV}"
    while true; do
      if kind get clusters 2>/dev/null | grep -qx "${KIND_CLUSTER_NAME:-infra-local}"; then
        kind export kubeconfig --name "${KIND_CLUSTER_NAME:-infra-local}" --kubeconfig /tmp/kind-kubeconfig >/dev/null 2>&1 || true
      fi
      KUBECONFIG=/tmp/kind-kubeconfig "$REPO_ROOT/scripts/start-port-forwards.sh" >/tmp/infra-port-forward-watchdog-iteration.log 2>&1 || true
      sleep "${INTERVAL_SECONDS:-30}"
    done
  ' >"$LOG_FILE" 2>&1 &

  echo "$!" >"$PID_FILE"
  echo "Watchdog started (PID: $!)."
  echo "Log: $LOG_FILE"
}

stop_watchdog() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    kill "$(cat "$PID_FILE")" >/dev/null 2>&1 || true
    rm -f "$PID_FILE"
    echo "Watchdog stopped."
    return 0
  fi
  rm -f "$PID_FILE"
  echo "Watchdog is not running."
}

status_watchdog() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "Watchdog running (PID: $(cat "$PID_FILE"))."
  else
    echo "Watchdog not running."
  fi
}

cd "$REPO_ROOT"
case "${1:-start}" in
  start)
    start_watchdog
    ;;
  stop)
    stop_watchdog
    ;;
  status)
    status_watchdog
    ;;
  *)
    echo "Usage: ./scripts/keep-port-forwards.sh [start|stop|status]"
    exit 1
    ;;
esac

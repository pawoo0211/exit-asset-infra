#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="/tmp/infra-alive-watchdog.pid"
LOG_FILE="/tmp/infra-alive-watchdog.log"
LOOP_LOG="/tmp/infra-alive-watchdog-iteration.log"
INTERVAL="${INTERVAL_SECONDS:-15}"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-infra-local}"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-/tmp/kind-kubeconfig}"
HUE_START_SCRIPT="/Users/parksang-kwon/hue-local/start-hue.sh"

start_watchdog() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "Infra watchdog already running (PID: $(cat "$PID_FILE"))."
    return 0
  fi

  REPO_ROOT_ENV="$REPO_ROOT" \
  KIND_CLUSTER_NAME_ENV="$KIND_CLUSTER_NAME" \
  KUBECONFIG_PATH_ENV="$KUBECONFIG_PATH" \
  HUE_START_SCRIPT_ENV="$HUE_START_SCRIPT" \
  INTERVAL_SECONDS_ENV="$INTERVAL" \
  nohup bash -lc '
    set -euo pipefail
    REPO_ROOT="$REPO_ROOT_ENV"
    KIND_CLUSTER_NAME="$KIND_CLUSTER_NAME_ENV"
    KUBECONFIG_PATH="$KUBECONFIG_PATH_ENV"
    HUE_START_SCRIPT="$HUE_START_SCRIPT_ENV"
    INTERVAL_SECONDS="$INTERVAL_SECONDS_ENV"

    while true; do
      {
        date

        if kind get clusters 2>/dev/null | grep -qx "$KIND_CLUSTER_NAME"; then
          kind export kubeconfig --name "$KIND_CLUSTER_NAME" --kubeconfig "$KUBECONFIG_PATH" >/dev/null 2>&1 || true
        fi

        if KUBECONFIG="$KUBECONFIG_PATH" kubectl get nodes --request-timeout=8s >/dev/null 2>&1; then
          KUBECONFIG="$KUBECONFIG_PATH" kubectl get pods -A --no-headers \
            | awk '"'"'$1 !~ /^(kube-system|kafka|local-path-storage)$/ && $4 ~ /(CrashLoopBackOff|Error|ImagePullBackOff|RunContainerError|CreateContainerError)/ {print $1" "$2}'"'"' \
            | while read -r ns pod; do
                if [[ -n "$ns" && -n "$pod" ]]; then
                  KUBECONFIG="$KUBECONFIG_PATH" kubectl delete pod -n "$ns" "$pod" --ignore-not-found=true >/dev/null 2>&1 || true
                fi
              done

          KUBECONFIG="$KUBECONFIG_PATH" "$REPO_ROOT/scripts/start-port-forwards.sh" >/dev/null 2>&1 || true
        fi

        if [[ -x "$HUE_START_SCRIPT" ]]; then
          if ! docker ps --format "{{.Names}}" | grep -qx "hue-local"; then
            "$HUE_START_SCRIPT" >/dev/null 2>&1 || true
          fi
        fi
      } >"/tmp/infra-alive-watchdog-iteration.log" 2>&1

      sleep "$INTERVAL_SECONDS"
    done
  ' >"$LOG_FILE" 2>&1 &

  echo "$!" >"$PID_FILE"
  echo "Infra watchdog started (PID: $!)."
  echo "Log: $LOG_FILE"
  echo "Loop log: $LOOP_LOG"
}

stop_watchdog() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    kill "$(cat "$PID_FILE")" >/dev/null 2>&1 || true
    rm -f "$PID_FILE"
    echo "Infra watchdog stopped."
    return 0
  fi
  rm -f "$PID_FILE"
  echo "Infra watchdog is not running."
}

status_watchdog() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "Infra watchdog running (PID: $(cat "$PID_FILE"))."
  else
    echo "Infra watchdog not running."
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
    echo "Usage: ./scripts/keep-infra-alive.sh [start|stop|status]"
    exit 1
    ;;
esac

#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VENV_PATH="${VENV_PATH:-$HOME/.venvs/dbt312}"
PROJECT_DIR="$REPO_ROOT/dbt/project"
PROFILES_DIR="$REPO_ROOT/dbt/profiles"
LOCAL_PORT="${1:-18103}"
PID_FILE="/tmp/dbt-docs-${LOCAL_PORT}.pid"
LOG_FILE="/tmp/dbt-docs-${LOCAL_PORT}.log"

if [[ ! -x "$VENV_PATH/bin/dbt" ]]; then
  echo "dbt is not installed. Run: ./dbt/scripts/install.sh"
  exit 1
fi

if lsof -nP -iTCP:"$LOCAL_PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "dbt docs already running on http://localhost:$LOCAL_PORT"
    echo "PID: $(cat "$PID_FILE")"
    exit 0
  fi
  echo "Port $LOCAL_PORT is already in use."
  exit 1
fi

"$VENV_PATH/bin/dbt" deps --project-dir "$PROJECT_DIR" --profiles-dir "$PROFILES_DIR" >/dev/null 2>&1 || true
"$VENV_PATH/bin/dbt" docs generate --project-dir "$PROJECT_DIR" --profiles-dir "$PROFILES_DIR" >/dev/null

nohup "$VENV_PATH/bin/dbt" docs serve --project-dir "$PROJECT_DIR" --profiles-dir "$PROFILES_DIR" --port "$LOCAL_PORT" --no-browser >"$LOG_FILE" 2>&1 &
DOCS_PID=$!
echo "$DOCS_PID" > "$PID_FILE"
sleep 2

if kill -0 "$DOCS_PID" >/dev/null 2>&1; then
  echo "dbt Docs -> http://localhost:$LOCAL_PORT"
  echo "PID: $DOCS_PID"
  echo "Log: $LOG_FILE"
  exit 0
fi

echo "Failed to start dbt docs server. Check log: $LOG_FILE"
exit 1

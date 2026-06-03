#!/usr/bin/env bash

set -euo pipefail

VENV_PATH="${VENV_PATH:-$HOME/.venvs/dbt312}"

python3.12 -m venv "$VENV_PATH"
"$VENV_PATH/bin/pip" install --upgrade pip
"$VENV_PATH/bin/pip" install dbt-core dbt-clickhouse
"$VENV_PATH/bin/dbt" --version

echo "dbt installed in: $VENV_PATH"

#!/usr/bin/env bash

set -euo pipefail

if [[ "${SKIP_HDFS_PREP:-0}" == "1" ]]; then
  echo "Skipping HDFS preparation (SKIP_HDFS_PREP=1)."
  exit 0
fi

if ! command -v hdfs >/dev/null 2>&1; then
  echo "[WARN] 'hdfs' command not found on host."
  echo "Install/enable Hadoop locally and start it (see /Users/parksang-kwon/hadoop-local)."
  exit 1
fi

echo "Checking local HDFS reachability..."
if ! hdfs dfs -ls / >/dev/null 2>&1; then
  echo "[ERROR] HDFS is unreachable."
  echo "Start Hadoop locally, then retry:"
  echo "  /Users/parksang-kwon/hadoop-local/start-services.sh"
  echo "  /Users/parksang-kwon/hadoop-local/status-hadoop.sh"
  exit 1
fi

echo "Preparing HDFS directories for k3s workloads..."
hdfs dfs -mkdir -p /spark-history >/dev/null 2>&1 || true
hdfs dfs -mkdir -p /user/hive/warehouse >/dev/null 2>&1 || true
hdfs dfs -mkdir -p /paimon/warehouse >/dev/null 2>&1 || true
hdfs dfs -mkdir -p /iceberg/warehouse >/dev/null 2>&1 || true

# Dev-friendly permissions.
hdfs dfs -chmod 777 /spark-history >/dev/null 2>&1 || true
hdfs dfs -chmod -R 777 /user/hive >/dev/null 2>&1 || true
hdfs dfs -chmod -R 777 /paimon >/dev/null 2>&1 || true
hdfs dfs -chmod -R 777 /iceberg >/dev/null 2>&1 || true

echo "HDFS preparation complete."

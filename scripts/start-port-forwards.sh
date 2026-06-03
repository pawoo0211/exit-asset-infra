#!/usr/bin/env bash

# Start all port-forwards so that UI URLs (Kafka UI, Airflow, Prometheus, etc.) work.
# Run this after deploy-all.sh, or when port-forwards have stopped (e.g. after terminal close).
# Usage: ./scripts/start-port-forwards.sh

set -euo pipefail

export GODEBUG="${GODEBUG:-http2client=0}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KAFKA_UI_LOCAL_PORT="${KAFKA_UI_LOCAL_PORT:-18080}"
AIRFLOW_LOCAL_PORT="${AIRFLOW_LOCAL_PORT:-18081}"
MINIO_API_LOCAL_PORT="${MINIO_API_LOCAL_PORT:-19000}"
MINIO_CONSOLE_LOCAL_PORT="${MINIO_CONSOLE_LOCAL_PORT:-19001}"
MONGODB_LOCAL_PORT="${MONGODB_LOCAL_PORT:-27017}"
SPARK_HISTORY_LOCAL_PORT="${SPARK_HISTORY_LOCAL_PORT:-18084}"
STARROCKS_FE_LOCAL_PORT="${STARROCKS_FE_LOCAL_PORT:-19030}"
HIVE_METASTORE_LOCAL_PORT="${HIVE_METASTORE_LOCAL_PORT:-19083}"
NESSIE_LOCAL_PORT="${NESSIE_LOCAL_PORT:-19120}"
SCHEMA_REGISTRY_LOCAL_PORT="${SCHEMA_REGISTRY_LOCAL_PORT:-18085}"
KAFKA_CONNECT_LOCAL_PORT="${KAFKA_CONNECT_LOCAL_PORT:-18086}"
DEBEZIUM_LOCAL_PORT="${DEBEZIUM_LOCAL_PORT:-18087}"
PROMETHEUS_LOCAL_PORT="${PROMETHEUS_LOCAL_PORT:-19090}"
GRAFANA_LOCAL_PORT="${GRAFANA_LOCAL_PORT:-13000}"
HARBOR_LOCAL_PORT="${HARBOR_LOCAL_PORT:-18443}"
ARGOCD_LOCAL_PORT="${ARGOCD_LOCAL_PORT:-18083}"
KSQLDB_LOCAL_PORT="${KSQLDB_LOCAL_PORT:-18088}"
ZEPPELIN_LOCAL_PORT="${ZEPPELIN_LOCAL_PORT:-18089}"
STREAMPARK_LOCAL_PORT="${STREAMPARK_LOCAL_PORT:-18092}"
FLINK_LOCAL_PORT="${FLINK_LOCAL_PORT:-18093}"
PYDANTICAI_LOCAL_PORT="${PYDANTICAI_LOCAL_PORT:-18094}"
CLICKHOUSE_WEB_LOCAL_PORT="${CLICKHOUSE_WEB_LOCAL_PORT:-18102}"
CLICKHOUSE_HTTP_LOCAL_PORT="${CLICKHOUSE_HTTP_LOCAL_PORT:-18101}"
LOKI_LOCAL_PORT="${LOKI_LOCAL_PORT:-18104}"

ensure_cluster() {
  for _ in 1 2 3; do
    if kubectl cluster-info >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  if kubectl config get-contexts colima >/dev/null 2>&1; then
    kubectl config use-context colima >/dev/null 2>&1 || true
    for _ in 1 2 3; do
      if kubectl cluster-info >/dev/null 2>&1; then
        return 0
      fi
      sleep 1
    done
  fi

  "$REPO_ROOT/scripts/setup-k3s-colima.sh" >/dev/null 2>&1 || true
  kubectl cluster-info >/dev/null 2>&1
}

if ! ensure_cluster; then
  echo "Kubernetes cluster is unreachable. Start Colima first: ./scripts/setup-k3s-colima.sh"
  exit 1
fi

echo "Context: $(kubectl config current-context 2>/dev/null || echo 'unknown')"
echo "Starting port-forwards (services must already be deployed)..."
echo ""

run_pf() {
  local name="$1"
  shift

  # Port-forward can fail transiently when the Colima apiserver port-forward reconnects.
  for attempt in 1 2 3; do
    ensure_cluster >/dev/null 2>&1 || true
    if "$@"; then
      echo "[OK] $name"
      return 0
    fi
    sleep 2
  done

  echo "[SKIP] $name (service may not be deployed yet, or cluster is unstable)"
  return 1
}

run_pf "Kafka UI" "$REPO_ROOT/kafka/scripts/port-forward-kafka-ui.sh" "$KAFKA_UI_LOCAL_PORT" --background || true
run_pf "Airflow" "$REPO_ROOT/airflow/scripts/port-forward.sh" "$AIRFLOW_LOCAL_PORT" --background || true
run_pf "MinIO" "$REPO_ROOT/minio/scripts/port-forward.sh" "$MINIO_API_LOCAL_PORT" "$MINIO_CONSOLE_LOCAL_PORT" --background || true
run_pf "MongoDB" "$REPO_ROOT/mongodb/scripts/port-forward.sh" "$MONGODB_LOCAL_PORT" --background || true
run_pf "Spark History" "$REPO_ROOT/spark/scripts/port-forward.sh" "$SPARK_HISTORY_LOCAL_PORT" --background || true
run_pf "StarRocks FE" "$REPO_ROOT/starrocks/scripts/port-forward-fe.sh" "$STARROCKS_FE_LOCAL_PORT" --background || true
run_pf "Hive Metastore" "$REPO_ROOT/hive-metastore/scripts/port-forward.sh" "$HIVE_METASTORE_LOCAL_PORT" --background || true
run_pf "Nessie" "$REPO_ROOT/iceberg/scripts/port-forward.sh" "$NESSIE_LOCAL_PORT" --background || true
run_pf "Schema Registry" "$REPO_ROOT/schema-registry/scripts/port-forward.sh" "$SCHEMA_REGISTRY_LOCAL_PORT" --background || true
run_pf "Kafka Connect" "$REPO_ROOT/kafka-connect/scripts/port-forward.sh" "$KAFKA_CONNECT_LOCAL_PORT" --background || true
run_pf "Debezium" "$REPO_ROOT/debezium/scripts/port-forward.sh" "$DEBEZIUM_LOCAL_PORT" --background || true
run_pf "Prometheus" "$REPO_ROOT/prometheus/scripts/port-forward.sh" "$PROMETHEUS_LOCAL_PORT" --background || true
run_pf "Grafana" "$REPO_ROOT/grafana/scripts/port-forward.sh" "$GRAFANA_LOCAL_PORT" --background || true
run_pf "Harbor" "$REPO_ROOT/harbor/scripts/port-forward.sh" "$HARBOR_LOCAL_PORT" --background || true
run_pf "Argo CD" "$REPO_ROOT/argocd/scripts/port-forward.sh" "$ARGOCD_LOCAL_PORT" --background || true
run_pf "ksqlDB" "$REPO_ROOT/kafka/scripts/port-forward-ksqldb.sh" "$KSQLDB_LOCAL_PORT" --background || true
run_pf "Zeppelin" "$REPO_ROOT/zeppelin/scripts/port-forward.sh" "$ZEPPELIN_LOCAL_PORT" --background || true
run_pf "StreamPark" "$REPO_ROOT/streampark/scripts/port-forward.sh" "$STREAMPARK_LOCAL_PORT" --background || true
run_pf "Flink" "$REPO_ROOT/flink/scripts/port-forward.sh" "$FLINK_LOCAL_PORT" --background || true
run_pf "PydanticAI" "$REPO_ROOT/pydanticai/scripts/port-forward.sh" "$PYDANTICAI_LOCAL_PORT" --background || true
run_pf "ClickHouse" "$REPO_ROOT/clickhouse/scripts/port-forward.sh" "$CLICKHOUSE_WEB_LOCAL_PORT" "$CLICKHOUSE_HTTP_LOCAL_PORT" --background || true
run_pf "Loki" "$REPO_ROOT/loki/scripts/port-forward.sh" "$LOKI_LOCAL_PORT" --background || true

echo ""
# Check if any port-forward is actually listening
ANY_PF=0
for port in $KAFKA_UI_LOCAL_PORT $AIRFLOW_LOCAL_PORT $PROMETHEUS_LOCAL_PORT $GRAFANA_LOCAL_PORT; do
  lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 && ANY_PF=1 || true
done
if [[ $ANY_PF -eq 0 ]]; then
  echo "No port-forwards are listening. If all services were [SKIP], deploy first: ./scripts/deploy-all.sh"
  echo "Then run: ./scripts/start-port-forwards.sh"
  echo ""
fi
echo "Port-forwards started. UI URLs:"
echo "  Kafka UI:    http://localhost:${KAFKA_UI_LOCAL_PORT}/ui"
echo "  Airflow:     http://localhost:${AIRFLOW_LOCAL_PORT}"
echo "  Prometheus:  http://localhost:${PROMETHEUS_LOCAL_PORT}"
echo "  Grafana:     http://localhost:${GRAFANA_LOCAL_PORT}"
echo "  MinIO:       http://localhost:${MINIO_CONSOLE_LOCAL_PORT}"
echo "  Spark History: http://localhost:${SPARK_HISTORY_LOCAL_PORT}"
echo "  Harbor:      http://localhost:${HARBOR_LOCAL_PORT}"
echo "  Argo CD:     http://localhost:${ARGOCD_LOCAL_PORT}"
echo "  ksqlDB:      http://localhost:${KSQLDB_LOCAL_PORT}"
echo "  Zeppelin:    http://localhost:${ZEPPELIN_LOCAL_PORT}"
echo "  StreamPark:  http://localhost:${STREAMPARK_LOCAL_PORT}"
echo "  Flink:       http://localhost:${FLINK_LOCAL_PORT}"
echo "  PydanticAI:  http://localhost:${PYDANTICAI_LOCAL_PORT}"
echo "  ClickHouse:  http://localhost:${CLICKHOUSE_WEB_LOCAL_PORT}"
echo "  Loki:        http://localhost:${LOKI_LOCAL_PORT}"
echo "  (full list in README)"

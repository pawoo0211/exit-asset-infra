#!/usr/bin/env bash

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
ZEPPELIN_LOCAL_PORT="${ZEPPELIN_LOCAL_PORT:-18089}"
STREAMPARK_LOCAL_PORT="${STREAMPARK_LOCAL_PORT:-18092}"
FLINK_LOCAL_PORT="${FLINK_LOCAL_PORT:-18093}"
PYDANTICAI_LOCAL_PORT="${PYDANTICAI_LOCAL_PORT:-18094}"
CLICKHOUSE_WEB_LOCAL_PORT="${CLICKHOUSE_WEB_LOCAL_PORT:-18102}"
CLICKHOUSE_HTTP_LOCAL_PORT="${CLICKHOUSE_HTTP_LOCAL_PORT:-18101}"
LOKI_LOCAL_PORT="${LOKI_LOCAL_PORT:-18104}"

"$REPO_ROOT/scripts/deploy-via-argocd.sh"
"$REPO_ROOT/scripts/start-port-forwards.sh"
exit 0

# Wait for cluster to be reachable (retry for transient API unavailability)
wait_for_cluster() {
  local max_attempts="${1:-12}"
  local attempt=1
  while ! kubectl cluster-info >/dev/null 2>&1; do
    if [[ $attempt -ge $max_attempts ]]; then
      return 1
    fi
    echo "Waiting for Kubernetes API... (attempt $attempt/$max_attempts)"
    sleep 5
    attempt=$((attempt + 1))
  done
  return 0
}

if ! wait_for_cluster 6; then
  CURRENT_CONTEXT="$(kubectl config current-context 2>/dev/null || true)"
  if [[ "$CURRENT_CONTEXT" == "colima" ]]; then
    echo "Kubernetes cluster is unreachable. Starting k3s on Colima..."
    "$REPO_ROOT/scripts/setup-k3s-colima.sh"
  else
    echo "Kubernetes cluster is unreachable on context: ${CURRENT_CONTEXT:-unknown}"
    echo "Skipping Colima auto-recovery because current context is not colima."
    exit 1
  fi

  if ! wait_for_cluster 24; then
    echo "Kubernetes is still unreachable after setup."
    echo "Current context: $(kubectl config current-context 2>/dev/null || echo unknown)"
    echo "kubectl contexts:"
    kubectl config get-contexts || true
    echo "Colima status:"
    colima status || true
    exit 1
  fi
fi

# Ensure cluster is stable before starting deploys (avoids transient API errors)
echo "Checking cluster readiness..."
if ! wait_for_cluster 12; then
  echo "Kubernetes API did not become stable. Try: ./scripts/setup-k3s-colima.sh"
  exit 1
fi

# Retry a command up to 3 times (handles transient API connection errors)
run_with_retry() {
  local max_attempts=3
  local attempt=1
  while true; do
    if "$@"; then
      return 0
    fi
    if [[ $attempt -ge $max_attempts ]]; then
      echo "Failed after $max_attempts attempts."
      return 1
    fi
    echo "Retrying in 15s... (attempt $attempt/$max_attempts)"
    sleep 15
    attempt=$((attempt + 1))
  done
}

# Deploy steps: do not exit on first failure so we still run port-forwards at the end
DEPLOY_FAILED=0
set +e

echo "Deploying kafka..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" kafka || DEPLOY_FAILED=1

echo "Deploying kafka-topics..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" kafka-topics || DEPLOY_FAILED=1
echo "Deploying ksqlDB..."
run_with_retry "$REPO_ROOT/kafka/scripts/deploy-ksqldb.sh" || DEPLOY_FAILED=1
echo "Deploying Kafka UI..."
run_with_retry "$REPO_ROOT/kafka/scripts/deploy-kafka-ui.sh" || DEPLOY_FAILED=1

echo "Deploying postgresql..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" postgresql || DEPLOY_FAILED=1
echo "Deploying airflow..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" airflow || DEPLOY_FAILED=1
echo "Deploying minio..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" minio || DEPLOY_FAILED=1
echo "Deploying mongodb..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" mongodb || DEPLOY_FAILED=1

echo "Preparing external HDFS directories (macOS-local Hadoop)..."
run_with_retry "$REPO_ROOT/scripts/prepare-hdfs.sh" || DEPLOY_FAILED=1

echo "Deploying spark..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" spark || DEPLOY_FAILED=1
echo "Deploying starrocks..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" starrocks || DEPLOY_FAILED=1
echo "Deploying hive-metastore..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" hive-metastore || DEPLOY_FAILED=1
echo "Deploying iceberg..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" iceberg || DEPLOY_FAILED=1
echo "Deploying paimon..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" paimon || DEPLOY_FAILED=1
echo "Deploying schema-registry..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" schema-registry || DEPLOY_FAILED=1
echo "Deploying kafka-connect..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" kafka-connect || DEPLOY_FAILED=1
echo "Deploying debezium..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" debezium || DEPLOY_FAILED=1
echo "Deploying prometheus..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" prometheus || DEPLOY_FAILED=1
echo "Deploying grafana..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" grafana || DEPLOY_FAILED=1
echo "Deploying harbor..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" harbor || DEPLOY_FAILED=1
echo "Deploying argocd..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" argocd || DEPLOY_FAILED=1
echo "Deploying zeppelin..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" zeppelin || DEPLOY_FAILED=1
echo "Deploying streampark..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" streampark || DEPLOY_FAILED=1
echo "Deploying flink..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" flink || DEPLOY_FAILED=1
echo "Deploying pydanticai..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" pydanticai || DEPLOY_FAILED=1
echo "Deploying clickhouse..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" clickhouse || DEPLOY_FAILED=1
echo "Deploying loki..."
run_with_retry "$REPO_ROOT/scripts/deploy.sh" loki || DEPLOY_FAILED=1

set -e

echo "Starting port-forwards (so UI URLs work even if some deploys failed)..."
"$REPO_ROOT/kafka/scripts/port-forward-kafka-ui.sh" "$KAFKA_UI_LOCAL_PORT" --background || true
"$REPO_ROOT/airflow/scripts/port-forward.sh" "$AIRFLOW_LOCAL_PORT" --background || true
"$REPO_ROOT/minio/scripts/port-forward.sh" "$MINIO_API_LOCAL_PORT" "$MINIO_CONSOLE_LOCAL_PORT" --background || true
"$REPO_ROOT/mongodb/scripts/port-forward.sh" "$MONGODB_LOCAL_PORT" --background || true
"$REPO_ROOT/spark/scripts/port-forward.sh" "$SPARK_HISTORY_LOCAL_PORT" --background || true
"$REPO_ROOT/starrocks/scripts/port-forward-fe.sh" "$STARROCKS_FE_LOCAL_PORT" --background || true
"$REPO_ROOT/hive-metastore/scripts/port-forward.sh" "$HIVE_METASTORE_LOCAL_PORT" --background || true
"$REPO_ROOT/iceberg/scripts/port-forward.sh" "$NESSIE_LOCAL_PORT" --background || true
"$REPO_ROOT/schema-registry/scripts/port-forward.sh" "$SCHEMA_REGISTRY_LOCAL_PORT" --background || true
"$REPO_ROOT/kafka-connect/scripts/port-forward.sh" "$KAFKA_CONNECT_LOCAL_PORT" --background || true
"$REPO_ROOT/debezium/scripts/port-forward.sh" "$DEBEZIUM_LOCAL_PORT" --background || true
"$REPO_ROOT/prometheus/scripts/port-forward.sh" "$PROMETHEUS_LOCAL_PORT" --background || true
"$REPO_ROOT/grafana/scripts/port-forward.sh" "$GRAFANA_LOCAL_PORT" --background || true
"$REPO_ROOT/harbor/scripts/port-forward.sh" "$HARBOR_LOCAL_PORT" --background || true
"$REPO_ROOT/argocd/scripts/port-forward.sh" "$ARGOCD_LOCAL_PORT" --background || true
"$REPO_ROOT/zeppelin/scripts/port-forward.sh" "$ZEPPELIN_LOCAL_PORT" --background || true
"$REPO_ROOT/streampark/scripts/port-forward.sh" "$STREAMPARK_LOCAL_PORT" --background || true
"$REPO_ROOT/flink/scripts/port-forward.sh" "$FLINK_LOCAL_PORT" --background || true
"$REPO_ROOT/pydanticai/scripts/port-forward.sh" "$PYDANTICAI_LOCAL_PORT" --background || true
"$REPO_ROOT/clickhouse/scripts/port-forward.sh" "$CLICKHOUSE_WEB_LOCAL_PORT" "$CLICKHOUSE_HTTP_LOCAL_PORT" --background || true
"$REPO_ROOT/loki/scripts/port-forward.sh" "$LOKI_LOCAL_PORT" --background || true

if [[ $DEPLOY_FAILED -eq 1 ]]; then
  echo ""
  echo "Some deploy steps failed. UI URLs above work for deployed services only."
  echo "Re-run ./scripts/deploy-all.sh to retry failed steps, or ./scripts/start-port-forwards.sh to refresh port-forwards."
fi

echo "All modules deployed (or partial)."
echo "Kafka UI: http://localhost:${KAFKA_UI_LOCAL_PORT}/ui (cluster: local-kafka)"
echo "Airflow: http://localhost:${AIRFLOW_LOCAL_PORT}"
echo "MinIO API: http://localhost:${MINIO_API_LOCAL_PORT}"
echo "MinIO Console: http://localhost:${MINIO_CONSOLE_LOCAL_PORT}"
echo "MongoDB: mongodb://admin:admin1234@localhost:${MONGODB_LOCAL_PORT}/?authSource=admin"
echo "Spark History UI: http://localhost:${SPARK_HISTORY_LOCAL_PORT}"
echo "StarRocks FE(MySQL): localhost:${STARROCKS_FE_LOCAL_PORT}"
echo "Hive Metastore: thrift://localhost:${HIVE_METASTORE_LOCAL_PORT}"
echo "Nessie API: http://localhost:${NESSIE_LOCAL_PORT}"
echo "Schema Registry: http://localhost:${SCHEMA_REGISTRY_LOCAL_PORT}"
echo "Kafka Connect: http://localhost:${KAFKA_CONNECT_LOCAL_PORT}"
echo "Debezium Connect: http://localhost:${DEBEZIUM_LOCAL_PORT}"
echo "Prometheus: http://localhost:${PROMETHEUS_LOCAL_PORT}"
echo "Grafana: http://localhost:${GRAFANA_LOCAL_PORT}"
echo "Harbor UI: http://localhost:${HARBOR_LOCAL_PORT}"
echo "Argo CD UI: http://localhost:${ARGOCD_LOCAL_PORT}"
echo "Zeppelin UI: http://localhost:${ZEPPELIN_LOCAL_PORT}"
echo "StreamPark UI: http://localhost:${STREAMPARK_LOCAL_PORT}"
echo "Flink UI: http://localhost:${FLINK_LOCAL_PORT}"
echo "PydanticAI Runtime: http://localhost:${PYDANTICAI_LOCAL_PORT}"
echo "ClickHouse Web UI: http://localhost:${CLICKHOUSE_WEB_LOCAL_PORT}"
echo "ClickHouse HTTP: http://localhost:${CLICKHOUSE_HTTP_LOCAL_PORT}"
echo "Loki API: http://localhost:${LOKI_LOCAL_PORT}"
echo "ksqlDB: run ./kafka/scripts/port-forward-ksqldb.sh (default http://localhost:18088)"
echo ""
echo "If Kafka UI / Airflow / Prometheus etc. are unreachable, run: ./scripts/start-port-forwards.sh"

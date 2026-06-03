#!/usr/bin/env bash

set -euo pipefail

export GODEBUG="${GODEBUG:-http2client=0}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="${1:-}"
HELM_TIMEOUT="${HELM_TIMEOUT:-15m}"

if [[ -z "$MODULE" ]]; then
  echo "Usage: ./scripts/deploy.sh <argocd>"
  exit 1
fi

if [[ "$MODULE" != "argocd" ]]; then
  echo "GitOps-only mode enabled."
  echo "Use Argo CD sync instead of per-module deploy scripts."
  echo "Run: ./scripts/deploy-via-argocd.sh"
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required"
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required"
  exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
  CURRENT_CONTEXT="$(kubectl config current-context 2>/dev/null || true)"
  if [[ "$CURRENT_CONTEXT" == "colima" ]]; then
    echo "Kubernetes cluster is unreachable. Starting k3s on Colima..."
    "$REPO_ROOT/scripts/setup-k3s-colima.sh"
  else
    echo "Kubernetes cluster is unreachable on context: ${CURRENT_CONTEXT:-unknown}"
    echo "Skipping Colima auto-recovery because current context is not colima."
    exit 1
  fi

  if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "Kubernetes cluster is unreachable. Run: ./scripts/setup-k3s-colima.sh"
    exit 1
  fi
fi

case "$MODULE" in
  kafka)
    STRIMZI_RELEASE_NAME="strimzi-kafka-operator"
    STRIMZI_REPO_URL="https://strimzi.io/charts/"
    STRIMZI_CHART="strimzi/strimzi-kafka-operator"
    KAFKA_MANIFEST_PATH="$REPO_ROOT/kafka/manifests/strimzi-kafka.yaml"
    ;;
  kafka-mm2)
    KAFKA_MM2_DEPLOY_SCRIPT="$REPO_ROOT/kafka/mm2/scripts/deploy.sh"
    ;;
  airflow)
    CHART_PATH="$REPO_ROOT/airflow/chart"
    VALUES_PATH="$REPO_ROOT/airflow/chart/values.local.yaml"
    ;;
  kafka-topics)
    CHART_PATH="$REPO_ROOT/kafka/topics/chart"
    VALUES_PATH="$REPO_ROOT/kafka/topics/chart/values.local.yaml"
    ;;
  postgresql)
    CHART_PATH="$REPO_ROOT/postgresql/chart"
    VALUES_PATH="$REPO_ROOT/postgresql/chart/values.local.yaml"
    ;;
  prometheus)
    CHART_PATH="$REPO_ROOT/prometheus/chart"
    VALUES_PATH="$REPO_ROOT/prometheus/chart/values.local.yaml"
    ;;
  grafana)
    CHART_PATH="$REPO_ROOT/grafana/chart"
    VALUES_PATH="$REPO_ROOT/grafana/chart/values.local.yaml"
    ;;
  minio)
    MINIO_DEPLOY_SCRIPT="$REPO_ROOT/minio/scripts/deploy.sh"
    ;;
  mongodb)
    MONGODB_DEPLOY_SCRIPT="$REPO_ROOT/mongodb/scripts/deploy.sh"
    ;;
  spark)
    SPARK_DEPLOY_SCRIPT="$REPO_ROOT/spark/scripts/deploy.sh"
    ;;
  starrocks)
    STARROCKS_DEPLOY_SCRIPT="$REPO_ROOT/starrocks/scripts/deploy.sh"
    ;;
  hive-metastore)
    HIVE_METASTORE_DEPLOY_SCRIPT="$REPO_ROOT/hive-metastore/scripts/deploy.sh"
    ;;
  iceberg)
    ICEBERG_DEPLOY_SCRIPT="$REPO_ROOT/iceberg/scripts/deploy.sh"
    ;;
  paimon)
    PAIMON_DEPLOY_SCRIPT="$REPO_ROOT/paimon/scripts/deploy.sh"
    ;;
  schema-registry)
    SCHEMA_REGISTRY_DEPLOY_SCRIPT="$REPO_ROOT/schema-registry/scripts/deploy.sh"
    ;;
  kafka-connect)
    KAFKA_CONNECT_DEPLOY_SCRIPT="$REPO_ROOT/kafka-connect/scripts/deploy.sh"
    ;;
  debezium)
    DEBEZIUM_DEPLOY_SCRIPT="$REPO_ROOT/debezium/scripts/deploy.sh"
    ;;
  harbor)
    HARBOR_DEPLOY_SCRIPT="$REPO_ROOT/harbor/scripts/deploy.sh"
    ;;
  argocd)
    ARGOCD_DEPLOY_SCRIPT="$REPO_ROOT/argocd/scripts/deploy.sh"
    ;;
  zeppelin)
    ZEPPELIN_DEPLOY_SCRIPT="$REPO_ROOT/zeppelin/scripts/deploy.sh"
    ;;
  streampark)
    STREAMPARK_DEPLOY_SCRIPT="$REPO_ROOT/streampark/scripts/deploy.sh"
    ;;
  flink)
    FLINK_DEPLOY_SCRIPT="$REPO_ROOT/flink/scripts/deploy.sh"
    ;;
  pydanticai)
    PYDANTICAI_DEPLOY_SCRIPT="$REPO_ROOT/pydanticai/scripts/deploy.sh"
    ;;
  clickhouse)
    CLICKHOUSE_DEPLOY_SCRIPT="$REPO_ROOT/clickhouse/scripts/deploy.sh"
    ;;
  loki)
    LOKI_DEPLOY_SCRIPT="$REPO_ROOT/loki/scripts/deploy.sh"
    ;;
  *)
    echo "Unsupported module: $MODULE"
    echo "Supported modules: kafka, kafka-mm2, kafka-topics, airflow, postgresql, prometheus, grafana, minio, mongodb, spark, starrocks, hive-metastore, iceberg, paimon, schema-registry, kafka-connect, debezium, harbor, argocd, zeppelin, streampark, flink, pydanticai, clickhouse, loki"
    exit 1
    ;;
esac

if [[ "$MODULE" =~ ^(airflow|kafka-topics|postgresql|prometheus|grafana)$ ]]; then
  if [[ ! -d "$CHART_PATH" ]]; then
    echo "Chart not found: $CHART_PATH"
    exit 1
  fi

  if [[ ! -f "$VALUES_PATH" ]]; then
    echo "Values not found: $VALUES_PATH"
    exit 1
  fi
fi

if [[ "$MODULE" == "minio" ]] && [[ ! -f "$MINIO_DEPLOY_SCRIPT" ]]; then
  echo "MinIO deploy script not found: $MINIO_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "kafka-mm2" ]] && [[ ! -f "$KAFKA_MM2_DEPLOY_SCRIPT" ]]; then
  echo "Kafka MM2 deploy script not found: $KAFKA_MM2_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "mongodb" ]] && [[ ! -f "$MONGODB_DEPLOY_SCRIPT" ]]; then
  echo "MongoDB deploy script not found: $MONGODB_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "spark" ]] && [[ ! -f "$SPARK_DEPLOY_SCRIPT" ]]; then
  echo "Spark deploy script not found: $SPARK_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "starrocks" ]] && [[ ! -f "$STARROCKS_DEPLOY_SCRIPT" ]]; then
  echo "StarRocks deploy script not found: $STARROCKS_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "hive-metastore" ]] && [[ ! -f "$HIVE_METASTORE_DEPLOY_SCRIPT" ]]; then
  echo "Hive Metastore deploy script not found: $HIVE_METASTORE_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "iceberg" ]] && [[ ! -f "$ICEBERG_DEPLOY_SCRIPT" ]]; then
  echo "Iceberg deploy script not found: $ICEBERG_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "paimon" ]] && [[ ! -f "$PAIMON_DEPLOY_SCRIPT" ]]; then
  echo "Paimon deploy script not found: $PAIMON_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "schema-registry" ]] && [[ ! -f "$SCHEMA_REGISTRY_DEPLOY_SCRIPT" ]]; then
  echo "Schema Registry deploy script not found: $SCHEMA_REGISTRY_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "kafka-connect" ]] && [[ ! -f "$KAFKA_CONNECT_DEPLOY_SCRIPT" ]]; then
  echo "Kafka Connect deploy script not found: $KAFKA_CONNECT_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "debezium" ]] && [[ ! -f "$DEBEZIUM_DEPLOY_SCRIPT" ]]; then
  echo "Debezium deploy script not found: $DEBEZIUM_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "harbor" ]] && [[ ! -f "$HARBOR_DEPLOY_SCRIPT" ]]; then
  echo "Harbor deploy script not found: $HARBOR_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "argocd" ]] && [[ ! -f "$ARGOCD_DEPLOY_SCRIPT" ]]; then
  echo "Argo CD deploy script not found: $ARGOCD_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "zeppelin" ]] && [[ ! -f "$ZEPPELIN_DEPLOY_SCRIPT" ]]; then
  echo "Zeppelin deploy script not found: $ZEPPELIN_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "streampark" ]] && [[ ! -f "$STREAMPARK_DEPLOY_SCRIPT" ]]; then
  echo "StreamPark deploy script not found: $STREAMPARK_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "flink" ]] && [[ ! -f "$FLINK_DEPLOY_SCRIPT" ]]; then
  echo "Flink deploy script not found: $FLINK_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "pydanticai" ]] && [[ ! -f "$PYDANTICAI_DEPLOY_SCRIPT" ]]; then
  echo "PydanticAI deploy script not found: $PYDANTICAI_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "clickhouse" ]] && [[ ! -f "$CLICKHOUSE_DEPLOY_SCRIPT" ]]; then
  echo "ClickHouse deploy script not found: $CLICKHOUSE_DEPLOY_SCRIPT"
  exit 1
fi

if [[ "$MODULE" == "loki" ]] && [[ ! -f "$LOKI_DEPLOY_SCRIPT" ]]; then
  echo "Loki deploy script not found: $LOKI_DEPLOY_SCRIPT"
  exit 1
fi

RELEASE_NAME="${MODULE}-local"

case "$MODULE" in
  kafka)
    kubectl get ns kafka >/dev/null 2>&1 || kubectl create namespace kafka

    if helm -n kafka status "$RELEASE_NAME" >/dev/null 2>&1; then
      echo "Removing previous custom Kafka release ($RELEASE_NAME) before Strimzi deployment..."
      helm -n kafka uninstall "$RELEASE_NAME"
    fi

    helm repo add strimzi "$STRIMZI_REPO_URL" >/dev/null 2>&1 || true
    helm repo update >/dev/null

    echo "Installing Strimzi operator (with retry for API stability)..."
    for i in 1 2 3 4 5; do
      if helm upgrade --install "$STRIMZI_RELEASE_NAME" "$STRIMZI_CHART" \
        --namespace kafka \
        --create-namespace \
        --timeout "$HELM_TIMEOUT" \
        --set watchAnyNamespace=false; then
        break
      fi
      if [[ $i -eq 5 ]]; then
        echo "Helm install failed after 5 attempts. Check cluster: kubectl cluster-info"
        exit 1
      fi
      echo "Retrying in 15s... (attempt $i/5)"
      sleep 15
    done

    for i in 1 2 3 4 5; do
      if kubectl rollout status deployment/strimzi-cluster-operator -n kafka --timeout=300s; then
        break
      fi
      if [[ $i -eq 5 ]]; then
        echo "Strimzi operator rollout failed after 5 attempts."
        exit 1
      fi
      echo "Retrying rollout status in 10s... (attempt $i/5)"
      sleep 10
    done

    echo "Applying Kafka manifest (with retry for API server stability)..."
    for i in 1 2 3 4 5; do
      if kubectl apply -f "$KAFKA_MANIFEST_PATH" -n kafka; then
        break
      fi
      if [[ $i -eq 5 ]]; then
        echo "Failed to apply Kafka manifest after 5 attempts."
        exit 1
      fi
      echo "Retrying in 10s... (attempt $i/5)"
      sleep 10
    done

    kubectl wait --for=condition=Ready kafka.kafka.strimzi.io/kafka-local -n kafka --timeout=600s
    kubectl get pods -n kafka -o wide || true
    ;;
  kafka-mm2)
    "$KAFKA_MM2_DEPLOY_SCRIPT"
    ;;
  airflow)
    helm dependency update "$CHART_PATH"
    helm lint "$CHART_PATH"
    helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
      --namespace airflow \
      --create-namespace \
      --timeout "$HELM_TIMEOUT" \
      -f "$VALUES_PATH"
    kubectl get pods -n airflow -o wide || true
    ;;
  kafka-topics)
    helm lint "$CHART_PATH"
    for attempt in 1 2 3; do
      if helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
        --namespace kafka \
        --create-namespace \
        --timeout "$HELM_TIMEOUT" \
        -f "$VALUES_PATH"; then
        break
      fi
      if [[ $attempt -eq 3 ]]; then
        echo "kafka-topics deploy failed after 3 attempts."
        exit 1
      fi
      # Clear "another operation is in progress" (pending Helm release)
      echo "Clearing pending Helm release for $RELEASE_NAME..."
      # Try to get last deployed revision for rollback
      last_rev=$(helm -n kafka history "$RELEASE_NAME" 2>/dev/null | grep -E "^\s*[0-9]+\s+deployed" | tail -1 | awk '{print $1}' || echo "")
      if [[ -n "$last_rev" ]] && [[ "$last_rev" =~ ^[0-9]+$ ]]; then
        helm rollback "$RELEASE_NAME" "$last_rev" -n kafka 2>/dev/null || true
        sleep 3
      fi
      # If rollback didn't work or no revision, uninstall and delete Helm secret
      helm uninstall "$RELEASE_NAME" -n kafka 2>/dev/null || true
      # Delete Helm secret that might be stuck in pending state
      kubectl -n kafka delete secret "sh.helm.release.v1.$RELEASE_NAME.v*" 2>/dev/null || true
      sleep 5
    done
    kubectl get jobs -n kafka || true
    ;;
  postgresql)
    helm dependency update "$CHART_PATH"
    helm lint "$CHART_PATH"
    helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
      --namespace postgresql \
      --create-namespace \
      --timeout "$HELM_TIMEOUT" \
      -f "$VALUES_PATH"
    kubectl rollout status statefulset/"${RELEASE_NAME}" -n postgresql --timeout=300s
    kubectl get pods -n postgresql -o wide || true
    ;;
  prometheus)
    helm dependency update "$CHART_PATH"
    helm lint "$CHART_PATH"
    helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
      --namespace prometheus \
      --create-namespace \
      --timeout "$HELM_TIMEOUT" \
      -f "$VALUES_PATH"
    kubectl rollout status deployment/"${RELEASE_NAME}-server" -n prometheus --timeout=300s
    kubectl get pods -n prometheus -o wide || true
    ;;
  grafana)
    helm dependency update "$CHART_PATH"
    helm lint "$CHART_PATH"
    helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
      --namespace grafana \
      --create-namespace \
      --timeout "$HELM_TIMEOUT" \
      -f "$VALUES_PATH"
    kubectl rollout status deployment/"${RELEASE_NAME}" -n grafana --timeout=300s
    kubectl get pods -n grafana -o wide || true
    ;;
  minio)
    "$MINIO_DEPLOY_SCRIPT"
    ;;
  mongodb)
    "$MONGODB_DEPLOY_SCRIPT"
    ;;
  spark)
    "$SPARK_DEPLOY_SCRIPT"
    ;;
  starrocks)
    "$STARROCKS_DEPLOY_SCRIPT"
    ;;
  hive-metastore)
    "$HIVE_METASTORE_DEPLOY_SCRIPT"
    ;;
  iceberg)
    "$ICEBERG_DEPLOY_SCRIPT"
    ;;
  paimon)
    "$PAIMON_DEPLOY_SCRIPT"
    ;;
  schema-registry)
    "$SCHEMA_REGISTRY_DEPLOY_SCRIPT"
    ;;
  kafka-connect)
    "$KAFKA_CONNECT_DEPLOY_SCRIPT"
    ;;
  debezium)
    "$DEBEZIUM_DEPLOY_SCRIPT"
    ;;
  harbor)
    "$HARBOR_DEPLOY_SCRIPT"
    ;;
  argocd)
    "$ARGOCD_DEPLOY_SCRIPT"
    ;;
  zeppelin)
    "$ZEPPELIN_DEPLOY_SCRIPT"
    ;;
  streampark)
    "$STREAMPARK_DEPLOY_SCRIPT"
    ;;
  flink)
    "$FLINK_DEPLOY_SCRIPT"
    ;;
  pydanticai)
    "$PYDANTICAI_DEPLOY_SCRIPT"
    ;;
  clickhouse)
    "$CLICKHOUSE_DEPLOY_SCRIPT"
    ;;
  loki)
    "$LOKI_DEPLOY_SCRIPT"
    ;;
esac

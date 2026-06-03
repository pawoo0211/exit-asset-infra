#!/usr/bin/env bash

set -euo pipefail

export GODEBUG="${GODEBUG:-http2client=0}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-spark}"
SPARK_OPERATOR_NAMESPACE="${SPARK_OPERATOR_NAMESPACE:-spark-operator}"
SPARK_OPERATOR_RELEASE="${SPARK_OPERATOR_RELEASE:-spark-operator}"
SPARK_OPERATOR_CHART="${SPARK_OPERATOR_CHART:-spark-operator/spark-operator}"
HADOOP_CONFIG_MANIFEST="$REPO_ROOT/spark/manifests/hadoop-config.yaml"
SPARK_RBAC_MANIFEST="$REPO_ROOT/spark/manifests/spark-rbac.yaml"
HISTORY_MANIFEST="$REPO_ROOT/spark/manifests/spark-history-server.yaml"

wait_for_cluster() {
  local max_attempts="${1:-24}"
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

run_with_retry() {
  local max_attempts="${1:-3}"
  shift
  local attempt=1
  while true; do
    if "$@"; then
      return 0
    fi
    if [[ $attempt -ge $max_attempts ]]; then
      return 1
    fi
    echo "Retrying in 10s... (attempt $attempt/$max_attempts)"
    sleep 10
    attempt=$((attempt + 1))
  done
}

ensure_namespace() {
  local ns="$1"
  for _ in 1 2 3 4 5; do
    if kubectl get ns "$ns" >/dev/null 2>&1; then
      return 0
    fi
    kubectl create namespace "$ns" >/dev/null 2>&1 || true
    sleep 2
  done
  kubectl get ns "$ns" >/dev/null 2>&1
}

if ! wait_for_cluster 24; then
  echo "Kubernetes cluster is unreachable. Run: ./scripts/setup-k3s-colima.sh"
  exit 1
fi

helm repo add spark-operator https://kubeflow.github.io/spark-operator >/dev/null 2>&1 || true
helm repo update >/dev/null
ensure_namespace "$SPARK_OPERATOR_NAMESPACE"

# The Spark Operator chart may create RBAC in the target job namespace.
# Ensure it exists before installing the operator.
ensure_namespace "$NAMESPACE"

echo "Installing Spark Operator..."
run_with_retry 3 helm upgrade --install "$SPARK_OPERATOR_RELEASE" "$SPARK_OPERATOR_CHART" \
  --namespace "$SPARK_OPERATOR_NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout 10m \
  --set spark.jobNamespaces[0]="$NAMESPACE" \
  --set webhook.enable=true \
  --set spark.serviceAccount.create=false \
  --set spark.serviceAccount.name=spark

run_with_retry 3 kubectl -n "$NAMESPACE" apply -f "$HADOOP_CONFIG_MANIFEST"
run_with_retry 3 kubectl -n "$NAMESPACE" apply -f "$SPARK_RBAC_MANIFEST"
run_with_retry 3 kubectl -n "$NAMESPACE" apply -f "$HISTORY_MANIFEST"
run_with_retry 3 kubectl rollout status deployment/spark-history-server -n "$NAMESPACE" --timeout=300s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: ./spark/scripts/port-forward.sh"
echo "Run sample Spark app: kubectl -n $NAMESPACE apply -f $REPO_ROOT/spark/manifests/spark-pi-hdfs.yaml"

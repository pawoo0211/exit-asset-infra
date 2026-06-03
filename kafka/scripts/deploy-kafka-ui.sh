#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAMESPACE="${NAMESPACE:-kafka}"
KAFKA_SERVICE="${KAFKA_SERVICE:-kafka-local-kafka-bootstrap:9092}"
KSQLDB_SERVER="${KSQLDB_SERVER:-http://ksqldb-server:8088}"

kubectl -n "$NAMESPACE" get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
kubectl -n "$NAMESPACE" apply -f "$REPO_ROOT/kafka/manifests/kafka-ui.yaml"
kubectl -n "$NAMESPACE" set env deployment/kafka-ui \
  SERVER_SERVLET_CONTEXT_PATH=/ui \
  KAFKA_CLUSTERS_0_NAME=local-kafka \
  KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS="$KAFKA_SERVICE" \
  KAFKA_CLUSTERS_0_KSQLDBSERVER="$KSQLDB_SERVER"

kubectl rollout status deployment/kafka-ui -n "$NAMESPACE" --timeout=180s
kubectl get pods,svc -n "$NAMESPACE"

echo "Run: kubectl -n $NAMESPACE port-forward svc/kafka-ui 8080:8080"

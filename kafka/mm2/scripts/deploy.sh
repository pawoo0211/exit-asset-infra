#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
NAMESPACE="${NAMESPACE:-kafka}"
MIRROR_MANIFEST="$REPO_ROOT/kafka/mm2/manifests/kafka-mirror.yaml"
MM2_MANIFEST="$REPO_ROOT/kafka/mm2/manifests/mm2-local-to-mirror.yaml"

kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

kubectl -n "$NAMESPACE" apply -f "$MIRROR_MANIFEST"
for attempt in 1 2 3; do
  if kubectl wait --for=condition=Ready kafka.kafka.strimzi.io/kafka-mirror -n "$NAMESPACE" --timeout=600s; then
    break
  fi
  if [[ "$attempt" -eq 3 ]]; then
    echo "kafka-mirror is not Ready after retries."
    exit 1
  fi
  echo "Retrying kafka-mirror readiness wait in 20s..."
  sleep 20
done

kubectl -n "$NAMESPACE" apply -f "$MM2_MANIFEST"
for attempt in 1 2 3; do
  if kubectl wait --for=condition=Ready kafkamirrormaker2.kafka.strimzi.io/mm2-local-to-mirror -n "$NAMESPACE" --timeout=600s; then
    break
  fi
  if [[ "$attempt" -eq 3 ]]; then
    echo "mm2-local-to-mirror is not Ready after retries."
    kubectl -n "$NAMESPACE" get kafkamirrormaker2 mm2-local-to-mirror -o wide || true
    exit 1
  fi
  echo "Retrying mm2-local-to-mirror readiness wait in 20s..."
  sleep 20
done

kubectl -n "$NAMESPACE" get kafka,kafkamirrormaker2,pods | grep -E 'kafka-local|kafka-mirror|mm2-local-to-mirror|NAME' || true

echo "MM2 is running: source=kafka-local, target=kafka-mirror, resource=mm2-local-to-mirror"

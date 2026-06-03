#!/usr/bin/env bash

# Show k3s/Colima and pod/service status for local infra.
# Usage: ./scripts/status.sh

set -euo pipefail

echo "=== Cluster reachability ==="
if kubectl cluster-info >/dev/null 2>&1; then
  kubectl cluster-info
  echo ""
else
  echo "Cluster unreachable. Start with: ./scripts/setup-k3s-colima.sh"
  exit 1
fi

echo "=== Nodes ==="
kubectl get nodes -o wide 2>/dev/null || true
echo ""

echo "=== Namespaces (excluding kube-system) ==="
kubectl get ns -o name 2>/dev/null | grep -v kube-system || true
echo ""

echo "=== Services (by namespace) ==="
for ns in kafka airflow prometheus grafana minio mongodb spark starrocks hive-metastore iceberg schema-registry kafka-connect debezium harbor argocd postgresql flink pydanticai; do
  if kubectl get ns "$ns" >/dev/null 2>&1; then
    count=$(kubectl get svc -n "$ns" -o name 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -gt 0 ]]; then
      echo "--- $ns ---"
      kubectl get svc -n "$ns" 2>/dev/null | head -20
      echo ""
    fi
  fi
done

echo "=== Pods (not Running/Completed) ==="
kubectl get pods -A 2>/dev/null | grep -vE "Running|Completed|NAME" || true
echo ""

echo "=== Port-forwards (listening on localhost) ==="
for port in 18080 18081 18084 18093 18094 19090 13000 19001 18443 18083; do
  if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "  Port $port: in use"
  fi
done
echo "Tip: Run ./scripts/start-port-forwards.sh to start port-forwards for UI access."

#!/usr/bin/env bash

set -euo pipefail

MODE="${1:-stop}"

echo "[1/3] Stop local port-forwards if running"
for port in 18080 18081; do
  pid_file="/tmp/kafka-ui-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 18088 18089; do
  pid_file="/tmp/ksqldb-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped ksqlDB port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 13000 13001; do
  pid_file="/tmp/grafana-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Grafana port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 18081 18082; do
  pid_file="/tmp/airflow-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Airflow port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 19090 19091; do
  pid_file="/tmp/prometheus-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Prometheus port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for pair in 19000-19001 19002-19003; do
  pid_file="/tmp/minio-port-forward-${pair}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped MinIO port-forward PID $pf_pid (ports ${pair/-/,})"
    fi
    rm -f "$pid_file"
  fi
done

for port in 27017 27018; do
  pid_file="/tmp/mongodb-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped MongoDB port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 19030 19031; do
  pid_file="/tmp/starrocks-fe-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped StarRocks FE port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 19083 19084; do
  pid_file="/tmp/hive-metastore-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Hive Metastore port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 19120 19121; do
  pid_file="/tmp/nessie-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Nessie port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 18085 18095; do
  pid_file="/tmp/schema-registry-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Schema Registry port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 18086 18096; do
  pid_file="/tmp/kafka-connect-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Kafka Connect port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 18087 18097; do
  pid_file="/tmp/debezium-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Debezium port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 18443 18453; do
  pid_file="/tmp/harbor-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Harbor port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 18083 18093; do
  pid_file="/tmp/argocd-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Argo CD port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 18093 18094; do
  pid_file="/tmp/flink-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped Flink port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

for port in 18094 18095; do
  pid_file="/tmp/pydanticai-port-forward-${port}.pid"
  if [[ -f "$pid_file" ]]; then
    pf_pid="$(cat "$pid_file")"
    if kill -0 "$pf_pid" >/dev/null 2>&1; then
      kill "$pf_pid" || true
      echo "Stopped PydanticAI port-forward PID $pf_pid (port $port)"
    fi
    rm -f "$pid_file"
  fi
done

if [[ "$MODE" == "down" ]]; then
  echo "[2/3] Remove deployed resources (keep namespaces)"
  kubectl -n kafka delete kafka.kafka.strimzi.io kafka-local --ignore-not-found=true || true
  helm -n kafka status strimzi-kafka-operator >/dev/null 2>&1 && helm -n kafka uninstall strimzi-kafka-operator || true
  helm -n kafka status kafka-local >/dev/null 2>&1 && helm -n kafka uninstall kafka-local || true
  helm -n airflow status airflow-local >/dev/null 2>&1 && helm -n airflow uninstall airflow-local || true
  helm -n postgresql status postgresql-local >/dev/null 2>&1 && helm -n postgresql uninstall postgresql-local || true
  helm -n prometheus status prometheus-local >/dev/null 2>&1 && helm -n prometheus uninstall prometheus-local || true
  helm -n grafana status grafana-local >/dev/null 2>&1 && helm -n grafana uninstall grafana-local || true
  helm -n starrocks status starrocks-local >/dev/null 2>&1 && helm -n starrocks uninstall starrocks-local || true
  helm -n starrocks status starrocks-operator >/dev/null 2>&1 && helm -n starrocks uninstall starrocks-operator || true
  helm -n mysql status mysql-local >/dev/null 2>&1 && helm -n mysql uninstall mysql-local || true
  kubectl -n minio delete svc minio --ignore-not-found=true
  kubectl -n minio delete deployment minio --ignore-not-found=true
  kubectl -n minio delete pvc minio-data --ignore-not-found=true
  kubectl -n mongodb delete svc mongodb --ignore-not-found=true
  kubectl -n mongodb delete deployment mongodb --ignore-not-found=true
  kubectl -n mongodb delete pvc mongodb-data --ignore-not-found=true
  kubectl -n hive-metastore delete svc hive-metastore --ignore-not-found=true
  kubectl -n hive-metastore delete deployment hive-metastore --ignore-not-found=true
  kubectl -n hive-metastore delete pvc hive-metastore-data --ignore-not-found=true
  kubectl -n hive-metastore delete configmap hive-hadoop-config --ignore-not-found=true
  kubectl -n iceberg delete svc nessie --ignore-not-found=true
  kubectl -n iceberg delete deployment nessie --ignore-not-found=true
  kubectl -n paimon delete configmap paimon-catalog-config --ignore-not-found=true
  kubectl -n paimon delete configmap iceberg-catalog-config --ignore-not-found=true
  kubectl -n schema-registry delete svc schema-registry --ignore-not-found=true
  kubectl -n schema-registry delete deployment schema-registry --ignore-not-found=true
  kubectl -n kafka-connect delete svc kafka-connect --ignore-not-found=true
  kubectl -n kafka-connect delete deployment kafka-connect --ignore-not-found=true
  kubectl -n debezium delete svc debezium-connect --ignore-not-found=true
  kubectl -n debezium delete deployment debezium-connect --ignore-not-found=true
  helm -n harbor status harbor >/dev/null 2>&1 && helm -n harbor uninstall harbor || true
  helm -n argocd status argocd >/dev/null 2>&1 && helm -n argocd uninstall argocd || true
  kubectl -n kafka delete svc kafka-ui --ignore-not-found=true
  kubectl -n kafka delete deployment kafka-ui --ignore-not-found=true
  kubectl -n kafka delete svc ksqldb-server --ignore-not-found=true
  kubectl -n kafka delete deployment ksqldb-server --ignore-not-found=true
  kubectl -n flink delete svc flink-jobmanager --ignore-not-found=true
  kubectl -n flink delete deployment flink-jobmanager --ignore-not-found=true
  kubectl -n flink delete deployment flink-taskmanager --ignore-not-found=true
  kubectl -n pydanticai delete svc pydanticai-runtime --ignore-not-found=true
  kubectl -n pydanticai delete deployment pydanticai-runtime --ignore-not-found=true
fi

echo "[3/3] Stop k3s runtime (Colima)"
if command -v colima >/dev/null 2>&1; then
  colima stop || true
fi

if [[ "$MODE" == "down" ]]; then
  echo "Local infra resources removed and runtime stopped"
else
  echo "Runtime stopped (namespaces/resources preserved)"
  echo "Tip: use './scripts/shutdown-all.sh down' to remove deployed resources too"
fi

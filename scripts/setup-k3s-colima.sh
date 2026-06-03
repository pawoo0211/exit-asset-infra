#!/usr/bin/env bash

set -euo pipefail

# Colima port-forwarding for the Kubernetes API can be flaky with HTTP/2.
# Disabling the Go HTTP/2 client improves kubectl/helm stability.
export GODEBUG="${GODEBUG:-http2client=0}"

COLIMA_PROFILE="${COLIMA_PROFILE:-default}"
COLIMA_CPU="${COLIMA_CPU:-6}"
COLIMA_MEMORY="${COLIMA_MEMORY:-14}"
COLIMA_DISK="${COLIMA_DISK:-100}"

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

pick_reachable_apiserver_port() {
  local profile="$1"
  local vm_port=""
  local ports=()

  # Try to read the port that k3s is configured with inside the VM.
  vm_port=$(colima ssh -p "$profile" -- sudo awk '/server: https:\/\//{print $2}' /etc/rancher/k3s/k3s.yaml 2>/dev/null | awk -F: '{print $NF}' | tail -1 || true)
  if [[ -n "$vm_port" ]] && [[ "$vm_port" =~ ^[0-9]+$ ]]; then
    ports+=("$vm_port")
    ports+=($((vm_port + 1)))
  fi

  # Fallback to current kubeconfig port if available.
  local current_server=""
  current_server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || true)
  if [[ "$current_server" =~ :([0-9]+)$ ]]; then
    ports+=("${BASH_REMATCH[1]}")
  fi

  # De-dup while keeping order.
  local uniq_ports=()
  local seen=" "
  for p in "${ports[@]}"; do
    if [[ "$seen" != *" $p "* ]]; then
      uniq_ports+=("$p")
      seen+="$p "
    fi
  done

  for p in "${uniq_ports[@]}"; do
    if curl -sk --connect-timeout 1 "https://127.0.0.1:${p}/readyz" >/dev/null 2>&1; then
      echo "$p"
      return 0
    fi
  done

  return 1
}

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install from https://brew.sh"
  exit 1
fi

if ! command -v colima >/dev/null 2>&1; then
  brew install colima
fi

if ! command -v helm >/dev/null 2>&1; then
  brew install helm
fi

if ! command -v kubectl >/dev/null 2>&1; then
  brew install kubectl
fi

colima start -p "$COLIMA_PROFILE" --cpu "$COLIMA_CPU" --memory "$COLIMA_MEMORY" --disk "$COLIMA_DISK" --kubernetes
colima kubernetes start -p "$COLIMA_PROFILE" >/dev/null 2>&1 || true

# Colima may expose the apiserver on a different local port across restarts.
# Pick a reachable port and patch kubeconfig so kubectl is stable.
if PORT=$(pick_reachable_apiserver_port "$COLIMA_PROFILE" 2>/dev/null); then
  ctx="$(kubectl config current-context 2>/dev/null || true)"
  if [[ -n "$ctx" ]]; then
    cluster="$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$ctx\")].context.cluster}" 2>/dev/null || true)"
    if [[ -n "$cluster" ]]; then
      kubectl config set-cluster "$cluster" --server="https://127.0.0.1:${PORT}" >/dev/null 2>&1 || true
    fi
  fi
fi

# Colima's kube context name can vary by version/config.
# Try a few common ones and validate by calling cluster-info.
if ! kubectl cluster-info >/dev/null 2>&1; then
  for ctx in "colima" "colima-${COLIMA_PROFILE}"; do
    if kubectl config get-contexts "$ctx" >/dev/null 2>&1; then
      kubectl config use-context "$ctx" >/dev/null 2>&1 || true
      if kubectl cluster-info >/dev/null 2>&1; then
        break
      fi
    fi
  done
fi

# k3s API can take a while to become reachable after Colima start.
if ! wait_for_cluster 24; then
  # Sometimes the API forwarding socket is not ready; re-run kubernetes start and retry.
  colima kubernetes start -p "$COLIMA_PROFILE" >/dev/null 2>&1 || true
  if ! wait_for_cluster 24; then
    echo "Kubernetes is still unreachable after starting Colima."
    echo "kubectl contexts:"
    kubectl config get-contexts || true
    echo "Colima status:"
    colima status -p "$COLIMA_PROFILE" || true
    exit 1
  fi
fi

echo "k3s on Colima is ready (context: $(kubectl config current-context))"
kubectl get nodes -o wide

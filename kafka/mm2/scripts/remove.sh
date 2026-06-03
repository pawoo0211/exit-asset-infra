#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${NAMESPACE:-kafka}"

kubectl -n "$NAMESPACE" delete kafkamirrormaker2 mm2-local-to-mirror --ignore-not-found=true
kubectl -n "$NAMESPACE" delete kafka kafka-mirror --ignore-not-found=true
kubectl -n "$NAMESPACE" delete kafkanodepool kafka-mirror-pool --ignore-not-found=true

kubectl -n "$NAMESPACE" get kafka,kafkamirrormaker2 2>/dev/null || true

echo "Removed MM2 resources (mm2-local-to-mirror, kafka-mirror)."

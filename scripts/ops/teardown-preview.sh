#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="safezone-preview"
APP_DIR="deploy/preview/app"
PV_NAME="acer-nfs-1g-1"

echo "=== Teardown Preview Environment ==="

# 1. Delete ArgoCD Applications (triggers resource-finalizer cleanup)
echo "[1/3] Deleting ArgoCD Applications..."
kubectl delete -f "$APP_DIR/" --ignore-not-found
echo "      ArgoCD Applications deleted. Waiting for namespace resources to terminate..."

# Wait for pods to fully terminate — pvc-protection finalizer blocks until no pod mounts the PVC
kubectl wait pod --all --for=delete -n "$NAMESPACE" --timeout=120s 2>/dev/null || true

# 2. Delete PVCs (safe now that pods are gone)
echo "[2/3] Deleting PVCs..."
kubectl delete pvc --all -n "$NAMESPACE" --ignore-not-found --timeout=60s
echo "      PVCs deleted."

# 3. Reset static PV claimRef so it can be re-bound on next deploy
if kubectl get pv "$PV_NAME" &>/dev/null; then
  PV_STATUS=$(kubectl get pv "$PV_NAME" -o jsonpath='{.status.phase}')
  if [ "$PV_STATUS" = "Released" ]; then
    echo "[3/3] Clearing claimRef on PV $PV_NAME (status: Released -> Available)..."
    kubectl patch pv "$PV_NAME" --type=json \
      -p '[{"op":"remove","path":"/spec/claimRef"}]'
    echo "      PV $PV_NAME is now Available."
  else
    echo "[3/3] PV $PV_NAME status is '$PV_STATUS', skipping claimRef reset."
  fi
else
  echo "[3/3] PV $PV_NAME not found, skipping."
fi

echo ""
echo "=== Preview teardown complete ==="

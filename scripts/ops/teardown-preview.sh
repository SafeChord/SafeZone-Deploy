#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="safezone-preview"
APP_DIR="deploy/preview/app"
SIMULATOR_PVC="simulator-data-pvc"
SIMULATOR_PV="acer-nfs-1g-1"

echo "=== Teardown Preview App Layer ==="

# 1. Delete ArgoCD Applications (triggers resource-finalizer cleanup)
echo "[1/3] Deleting ArgoCD Applications..."
kubectl delete -f "$APP_DIR/" --ignore-not-found
echo "      ArgoCD Applications deleted."

# 2. Wait for app-layer pods to terminate (exclude infra: db, valkey)
echo "[2/3] Waiting for app-layer pods to terminate..."
APP_LABELS="app.kubernetes.io/instance in (safezone-foundation, safezone-core, safezone-ui, safezone-seed-schema, safezone-seed-cases)"
kubectl wait pod -l "$APP_LABELS" --for=delete -n "$NAMESPACE" --timeout=120s 2>/dev/null || true
echo "      App-layer pods terminated."

# 3. Clean up simulator PVC and reset static PV claimRef
echo "[3/3] Cleaning up simulator PVC/PV..."
kubectl delete pvc "$SIMULATOR_PVC" -n "$NAMESPACE" --ignore-not-found --timeout=60s

if kubectl get pv "$SIMULATOR_PV" &>/dev/null; then
  PV_STATUS=$(kubectl get pv "$SIMULATOR_PV" -o jsonpath='{.status.phase}')
  if [ "$PV_STATUS" = "Released" ]; then
    echo "      Clearing claimRef on PV $SIMULATOR_PV (Released -> Available)..."
    kubectl patch pv "$SIMULATOR_PV" --type=json \
      -p '[{"op":"remove","path":"/spec/claimRef"}]'
    echo "      PV $SIMULATOR_PV is now Available."
  else
    echo "      PV $SIMULATOR_PV status is '$PV_STATUS', skipping claimRef reset."
  fi
else
  echo "      PV $SIMULATOR_PV not found, skipping."
fi

echo ""
echo "=== Preview app teardown complete ==="
echo "Note: Infra resources (DB, Valkey, KafkaTopic) are untouched."

# --- Verify ---
echo ""
echo "--- Verify ---"
REMAINING=$(kubectl get application -n argocd -o jsonpath='{.items[?(@.metadata.labels.safezone\.io/stage!="preview-infra")].metadata.name}' 2>/dev/null || true)
if [ -z "$REMAINING" ]; then
  echo "  ArgoCD app-layer Applications: CLEAN"
else
  echo "  WARNING: app-layer Applications still found: $REMAINING"
fi

APP_PODS=$(kubectl get pod -n "$NAMESPACE" -l "$APP_LABELS" --no-headers 2>/dev/null | wc -l)
if [ "$APP_PODS" -eq 0 ]; then
  echo "  App-layer pods: CLEAN"
else
  echo "  WARNING: $APP_PODS app-layer pod(s) still running"
fi

if kubectl get pv "$SIMULATOR_PV" &>/dev/null; then
  PV_CHECK=$(kubectl get pv "$SIMULATOR_PV" -o jsonpath='{.status.phase}')
  echo "  PV $SIMULATOR_PV: $PV_CHECK"
else
  echo "  PV $SIMULATOR_PV: NOT FOUND (will be recreated by infra)"
fi

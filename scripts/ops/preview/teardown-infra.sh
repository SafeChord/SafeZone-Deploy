#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

# --- Pre-flight: ensure app layer is already gone ---
echo "=== Teardown Preview Infra Layer ==="

APP_NAMES=$(kubectl get application -n argocd -o jsonpath='{.items[?(@.metadata.labels.safezone\.io/stage!="preview-infra")].metadata.name}' 2>/dev/null || true)

if [ -n "$APP_NAMES" ]; then
  echo "ERROR: App-layer Applications still exist. Run teardown.sh first."
  echo "       Found: $APP_NAMES"
  exit 1
fi

echo "[pre] App layer confirmed clean."

# --- Step 1: Delete ApplicationSet (finalizer auto-cleans namespace, PV, secrets, valkey, etc.; CNPG Cluster skipped via Delete=false) ---
echo ""
echo "[1/4] Deleting infra ApplicationSet..."
kubectl delete applicationset "$APPSET_NAME" -n argocd --ignore-not-found
echo "      Waiting for child Applications + finalizer cleanup..."
kubectl wait application -n argocd -l "$INFRA_LABEL" \
  --for=delete --timeout=120s 2>/dev/null || true
echo "      Finalizer cleanup done."

# --- Step 2: Delete CNPG Cluster (skipped by finalizer, handle explicitly to control PVC cascade) ---
echo ""
echo "[2/4] Deleting CNPG Cluster '$CNPG_CLUSTER'..."
kubectl delete cluster.postgresql.cnpg.io "$CNPG_CLUSTER" -n "$NAMESPACE" --ignore-not-found --timeout=120s
echo "      CNPG Cluster deleted."

# --- Step 3: Delete KafkaTopic (lives in kafka namespace, not covered by ns deletion) ---
echo ""
echo "[3/4] Deleting KafkaTopic '$KAFKA_TOPIC' in '$KAFKA_TOPIC_NS'..."
kubectl delete kafkatopic "$KAFKA_TOPIC" -n "$KAFKA_TOPIC_NS" --ignore-not-found --timeout=60s
echo "      KafkaTopic deleted."

# --- Step 4: Delete namespace if it survived finalizer cleanup ---
echo ""
echo "[4/4] Deleting namespace '$NAMESPACE' (if still exists)..."
kubectl delete ns "$NAMESPACE" --ignore-not-found --timeout=120s
echo "      Namespace gone."

echo ""
echo "=== Preview infra teardown complete ==="

# --- Verify ---
echo ""
echo "--- Verify ---"
REMAINING=$(kubectl get application -n argocd -o jsonpath='{range .items[?(@.spec.project=="safezone")]}{.metadata.name}{" "}{end}' 2>/dev/null || true)
if [ -z "$REMAINING" ]; then
  echo "  ArgoCD Applications (project=safezone): CLEAN"
else
  echo "  WARNING: Applications still found: $REMAINING"
fi

if kubectl get ns "$NAMESPACE" &>/dev/null; then
  echo "  Namespace $NAMESPACE: STILL EXISTS"
else
  echo "  Namespace $NAMESPACE: CLEAN"
fi

if kubectl get kafkatopic "$KAFKA_TOPIC" -n "$KAFKA_TOPIC_NS" &>/dev/null; then
  echo "  WARNING: KafkaTopic $KAFKA_TOPIC still exists"
else
  echo "  KafkaTopic $KAFKA_TOPIC: CLEAN"
fi

echo ""
echo "To redeploy: bash scripts/ops/preview/setup-infra.sh"

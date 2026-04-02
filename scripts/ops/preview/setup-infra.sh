#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

echo "=== Setup Preview Infra Layer ==="

# --- Step 1: Ensure namespace exists ---
echo ""
echo "[1/4] Ensuring namespace '$NAMESPACE' exists..."
if kubectl get ns "$NAMESPACE" &>/dev/null; then
  echo "      Namespace already exists, skipping."
else
  kubectl create ns "$NAMESPACE"
  echo "      Namespace created."
fi

# --- Step 2: Apply infra ApplicationSet ---
echo ""
echo "[2/4] Applying infra ApplicationSet..."
kubectl apply -f "$APPSET_MANIFEST"
echo "      ApplicationSet applied. Waiting for child Applications..."
until [ "$(kubectl get application -n argocd -l "$INFRA_LABEL" --no-headers 2>/dev/null | wc -l)" -ge 4 ]; do
  sleep 3
done
echo "      4 child Applications created."

# --- Step 3: Wait for ArgoCD sync (Healthy + Synced) ---
echo ""
echo "[3/4] Waiting for infra Applications to sync..."
for APP in preview-infra-foundation preview-infra-security preview-infra-workloads preview-infra-init; do
  echo "  waiting for $APP..."
  until kubectl get application "$APP" -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null | grep -q "Healthy"; do
    sleep 5
  done
  echo "  $APP is Healthy."
done

# --- Step 4: Verify key workloads are running ---
echo ""
echo "[4/4] Verifying key workloads..."

echo "  Waiting for CNPG Cluster '$CNPG_CLUSTER' to be ready..."
until kubectl get cluster.postgresql.cnpg.io "$CNPG_CLUSTER" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null | grep -q "Cluster in healthy state"; do
  sleep 5
done
echo "  CNPG Cluster is healthy."

for STS in $VALKEY_STATEFULSETS; do
  echo "  Waiting for $STS..."
  kubectl rollout status statefulset/"$STS" -n "$NAMESPACE" --timeout=120s
done
echo "  Valkey instances ready."

echo ""
echo "=== Preview infra setup complete ==="
echo "Next: trigger 'Deploy Preview App Layer' from GitHub Actions UI."

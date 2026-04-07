#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

echo "=== Setup Staging Infra Layer ==="

# Namespace is created by foundation ArgoCD Application (namespace.yaml)

# --- Step 1: Apply infra ApplicationSet ---
echo ""
echo "[1/3] Applying infra ApplicationSet..."
kubectl apply -f "$APPSET_MANIFEST"
echo "      ApplicationSet applied. Waiting for child Applications..."
until [ "$(kubectl get application -n argocd -l "$INFRA_LABEL" --no-headers 2>/dev/null | wc -l)" -ge 4 ]; do
  sleep 3
done
echo "      4 child Applications created."

# --- Step 2: Wait for ArgoCD sync (Healthy + Synced) ---
echo ""
echo "[2/3] Waiting for infra Applications to sync..."
for APP in staging-infra-foundation staging-infra-security staging-infra-workloads staging-infra-init; do
  echo "  waiting for $APP..."
  until kubectl get application "$APP" -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null | grep -q "Healthy"; do
    sleep 5
  done
  echo "  $APP is Healthy."
done

# --- Step 3: Verify key workloads are running ---
echo ""
echo "[3/3] Verifying key workloads..."

echo "  Checking CNPG Database '$CNPG_DATABASE_CR' in '$CNPG_DATABASE_NS'..."
until kubectl get database.postgresql.cnpg.io "$CNPG_DATABASE_CR" -n "$CNPG_DATABASE_NS" \
  -o jsonpath='{.status.applied}' 2>/dev/null | grep -q "true"; do
  sleep 5
done
echo "  CNPG Database is applied."

for STS in $VALKEY_STATEFULSETS; do
  echo "  Waiting for $STS..."
  kubectl rollout status statefulset/"$STS" -n "$NAMESPACE" --timeout=120s
done
echo "  Valkey Cache ready."

echo ""
echo "=== Staging infra setup complete ==="
echo "Next: trigger 'Deploy Staging App Layer' from GitHub Actions UI."

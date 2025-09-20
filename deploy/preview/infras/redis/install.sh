set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)

echo "[INFO] Using script dir: $SCRIPT_DIR"

echo "[INFO] Applying SealedSecret..."
kubectl apply -f $SCRIPT_DIR/redis-sealed-secrets.yaml

echo "[PHASE 3] Deploy redis via ArgoCD Application"
kubectl apply -f $SCRIPT_DIR/application.yaml

echo "[✅ DONE] redis deployment triggered."
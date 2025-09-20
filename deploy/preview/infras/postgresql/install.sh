set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)

echo "[INFO] Applying SealedSecret..."
kubectl apply -f $SCRIPT_DIR/postgresql-sealed-secrets.yaml

echo "[PHASE 3] Deploy postgredb via ArgoCD Application"
kubectl apply -f $SCRIPT_DIR/application.yaml

echo "[✅ DONE] postgredb deployment triggered."
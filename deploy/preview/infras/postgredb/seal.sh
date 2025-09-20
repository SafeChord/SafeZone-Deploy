set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)

echo "[PHASE 1] Sealing Secret..."
kubeseal --controller-name=sealed-secrets \
         --controller-namespace=kube-system \
         --format yaml \
         < $SCRIPT_DIR/unsealed-secret.yaml \
         > $SCRIPT_DIR/postgredb-sealed-secrets.yaml
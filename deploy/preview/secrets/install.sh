set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)

echo "Installing Sealed Secrets..."
kubectl apply -f $SCRIPT_DIR
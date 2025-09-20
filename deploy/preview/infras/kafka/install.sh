#!/bin/bash

set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)

echo "[PHASE 3] Deploy kafka via ArgoCD Application"
kubectl apply -f $SCRIPT_DIR/application.yaml

echo "[✅ DONE] kafka deployment triggered."
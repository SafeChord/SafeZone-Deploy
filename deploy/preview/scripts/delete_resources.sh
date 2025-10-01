# this script deletes all resources created by the argo applications in the preview environment
# because the finalizer can not work properly in our k3s cluster, we have to do it manually

#!/bin/bash
set -e

# check $1 for namespace override
if [ -n "$1" ]; then
  NAMESPACE="$1"
else
  echo "No namespace provided, defaulting to 'safezone-preview'"
  NAMESPACE="safezone-preview"
fi

# This order is based on our deployment sequence; during deletion, we will execute in reverse order.
PHASES_TO_DELETE=(
    # "safezone-ui"
    # "safezone-seed-data"
    # "safezone-core"
    # "safezone-seed-init"
    "safezone-infra" 
)

echo "Starting cleanup of preview environment in namespace: $NAMESPACE"

echo "--- Deleting ArgoCD Applications ---"
for phase in "${PHASES_TO_DELETE[@]}"; do
    echo "Deleting Application: $phase"
    kubectl delete application "$phase" -n gitops --ignore-not-found
done

echo -e "\n--- Cleaning up orphaned resources by phase ---"
for phase in "${PHASES_TO_DELETE[@]}"; do
    echo "Cleaning resources for instance: $phase"
    
    kubectl delete all,ingress,networkpolicy,poddisruptionbudget,serviceaccount,configmap,sealedsecret \
      -n "$NAMESPACE" \
      -l "app.kubernetes.io/instance=$phase" \
      --ignore-not-found
    
    echo "Instance '$phase' resources marked for deletion."
    echo ""
done

echo "Cleanup script finished. Use 'kubectl get all,ingress,pvc -n $NAMESPACE' to monitor termination."
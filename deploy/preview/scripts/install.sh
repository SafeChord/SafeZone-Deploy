set -e

kubectl create configmap safezone-job-scripts \
  --from-file=deploy/preview/scripts/ \
  -n safezone-preview \
  --dry-run=client -o yaml | kubectl apply -f -
# How To Use
kubeseal --controller-name=sealed-secrets \
         --controller-namespace=kube-system \
         --format yaml \
         < unsealed-secrets.yaml \
         > sealed-secrets.yaml

kubectl apply -f sealed-secrets.yaml
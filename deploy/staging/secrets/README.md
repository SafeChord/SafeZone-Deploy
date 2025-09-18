# 加密含密文 yaml 檔
kubeseal --controller-name=sealed-secrets \
         --controller-namespace=kube-system \
         --format yaml \
         < unsealed-secrets.yaml \
         > sealed-secrets.yaml
為何需要加密? 將未加密密文 gitingnore 並透過 git 管理加密密文

# 部屬 sealed-secret 到 k8s，他將會自動解密成密文
kubectl apply -f sealed-secrets.yaml
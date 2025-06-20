export SA=safezone
export NS=gitops
export SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
export TOKEN=$(kubectl -n $NS create token safezone-ci-sa --duration=2h)
export CA=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

cat <<EOF > kubeconfig-$SA.yaml
apiVersion: v1
kind: Config
clusters:
- name: k3s
  cluster:
    certificate-authority-data: $CA
    server: $SERVER
users:
- name: $SA-user
  user:
    token: $TOKEN
contexts:
- name: $SA-context
  context:
    cluster: k3s
    user: $SA-user
    namespace: $NS
current-context: $SA-context
EOF

echo "已產生 kubeconfig-$SA.yaml"
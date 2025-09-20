set -e
# check service account name argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <service-account-name>"
  exit 1
fi

SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
TOKEN=$(kubectl -n gitops create token $1-ci-sa --duration=2h)
CA=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

cat <<EOF > kubeconfig-$1.yaml
apiVersion: v1
kind: Config
clusters:
- name: k3s
  cluster:
    certificate-authority-data: $CA
    server: $SERVER
users:
- name: $1-user
  user:
    token: $TOKEN
contexts:
- name: $1-context
  context:
    cluster: k3s
    user: $1-user
    namespace: $NS
current-context: $1-context
EOF

echo "已產生 kubeconfig-$1.yaml"
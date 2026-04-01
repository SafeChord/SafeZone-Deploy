set -e
# Usage: gen-kubeconfig.sh <namespace>
# Example: gen-kubeconfig.sh safezone-preview
#   → SA: safezone-preview-ci-sa in namespace safezone-preview
#   → Output: kubeconfig-safezone-preview.yaml

if [ $# -ne 1 ]; then
  echo "Usage: $0 <namespace>"
  exit 1
fi

NS="$1"
SA_NAME="$1-ci-sa"

SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
TOKEN=$(kubectl -n "$NS" create token "$SA_NAME" --duration=2h)
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

echo "Generated kubeconfig-$1.yaml (SA: $SA_NAME in namespace $NS)"

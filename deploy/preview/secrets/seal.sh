set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)

echo "Sealing AuthSecret..."
kubeseal --controller-name=sealed-secrets \
         --controller-namespace=kube-system \
         --format yaml \
         < $SCRIPT_DIR/unsealed/unsealed-authsecrets.yaml \
         > $SCRIPT_DIR/sealed-authsecrets.yaml

echo "Sealing CacheSecret..."
kubeseal --controller-name=sealed-secrets \
         --controller-namespace=kube-system \
         --format yaml \
         < $SCRIPT_DIR/unsealed/unsealed-cachesecrets.yaml \
         > $SCRIPT_DIR/sealed-cachesecrets.yaml

echo "Sealing DBSecret..."
kubeseal --controller-name=sealed-secrets \
         --controller-namespace=kube-system \
         --format yaml \
         < $SCRIPT_DIR/unsealed/unsealed-dbsecrets.yaml \
         > $SCRIPT_DIR/sealed-dbsecrets.yaml

echo "Sealing DockerSecret..."
kubeseal --controller-name=sealed-secrets \
         --controller-namespace=kube-system \
         --format yaml \
         < $SCRIPT_DIR/unsealed/unsealed-dockersecrets.yaml \
         > $SCRIPT_DIR/sealed-dockersecrets.yaml

echo "Sealing KafkaSecret..."
kubeseal --controller-name=sealed-secrets \
         --controller-namespace=kube-system \
         --format yaml \
         < $SCRIPT_DIR/unsealed/unsealed-kafkasecrets.yaml \
         > $SCRIPT_DIR/sealed-kafkasecrets.yaml

echo "Sealing RedisSecret..."
kubeseal --controller-name=sealed-secrets \
         --controller-namespace=kube-system \
         --format yaml \
         < $SCRIPT_DIR/unsealed/unsealed-redissecrets.yaml \
         > $SCRIPT_DIR/sealed-redissecrets.yaml

echo "Sealing RoleSecret..."
kubeseal --controller-name=sealed-secrets \
         --controller-namespace=kube-system \
         --format yaml \
         < $SCRIPT_DIR/unsealed/unsealed-rolesecrets.yaml \
         > $SCRIPT_DIR/sealed-rolesecrets.yaml
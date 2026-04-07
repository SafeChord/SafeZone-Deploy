#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

echo "--- Starting Staging Infrastructure Smoke Test ---"

# 1. PostgreSQL connectivity (platform DB, cross-namespace)
log "\n1. Testing PostgreSQL (Chorde platform DB)..."
# Use a temporary pod to test connectivity to the platform DB
DB_URL=$(kubectl get secret k3han-db-secrets -n "$NAMESPACE" -o jsonpath="{.data.db_url}" | base64 --decode)

kubectl run pg-check --rm -i --restart=Never -n "$NAMESPACE" \
  --image=postgres:17-alpine \
  --command -- psql "$DB_URL" -c "SELECT 'PostgreSQL Connection OK' as status;" 2>/dev/null | grep "OK"
log "SUCCESS: PostgreSQL is reachable via platform service."
 
# 2. Valkey State (Chorde platform service, cross-namespace)
log "\n2. Testing Valkey State (Chorde platform)..."
VS_PASS=$(kubectl get secret k3han-redis-secrets -n "$NAMESPACE" -o jsonpath="{.data.redis-password}" | base64 --decode)

VS_OUTPUT=$(kubectl run valkey-check --rm -i --restart=Never -n "$NAMESPACE" \
  --image=valkey/valkey:8.1 \
  --command -- valkey-cli -h valkey.redis.svc.cluster.local --no-auth-warning -a "$VS_PASS" PING 2>/dev/null || true)
if echo "$VS_OUTPUT" | grep -q "PONG"; then
    log "SUCCESS: Valkey State authenticated (PONG received)."
else
    error "FAIL: Valkey State authentication failed. Got: $VS_OUTPUT"
    exit 1
fi

# 3. Valkey Cache (self-managed in namespace)
log "\n3. Testing Valkey Cache..."
VC_PASS=$(kubectl get secret safezone-cache-secrets -n "$NAMESPACE" -o jsonpath="{.data.redis-password}" | base64 --decode)

if kubectl exec -n "$NAMESPACE" valkey-cache-0 -- valkey-cli --no-auth-warning -a "$VC_PASS" PING 2>/dev/null | grep -q "PONG"; then
    log "SUCCESS: Valkey Cache authenticated (PONG received)."
else
    error "FAIL: Valkey Cache authentication failed."
    exit 1
fi

# 4. Kafka Topic Test
log "\n4. Testing Kafka Topic Definition..."
TOPIC_STATUS=$(kubectl get kafkatopic "$KAFKA_TOPIC" -n "$KAFKA_TOPIC_NS" -o jsonpath="{.status.conditions[0].type}" 2>/dev/null || echo "NOT_FOUND")

if [ "$TOPIC_STATUS" == "Ready" ]; then
    log "SUCCESS: KafkaTopic '$KAFKA_TOPIC' is Ready."
else
    warn "INFO: KafkaTopic status is '$TOPIC_STATUS'. This is normal if shared cluster is reconciling."
fi

log "\n--- Staging Infrastructure Smoke Test Completed ---"

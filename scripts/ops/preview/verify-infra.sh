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

echo "--- Starting Preview Infrastructure Smoke Test ---"

# 1. PostgreSQL (CNPG) Test
log "\n1. Testing PostgreSQL (CloudNativePG)..."
PG_POD=$(kubectl get pod -n "$NAMESPACE" -l "cnpg.io/cluster=$CNPG_CLUSTER,role=primary" -o name | head -n 1)

if [ -z "$PG_POD" ]; then
    error "FAIL: CNPG primary pod not found in $NAMESPACE."
    exit 1
fi

log "Executing SQL check on $PG_POD..."
kubectl exec -n "$NAMESPACE" "$PG_POD" -c postgres -- \
    psql -U postgres -d postgres -c "SELECT 'PostgreSQL Connection OK' as status;" | grep "OK"
log "SUCCESS: PostgreSQL is reachable and authenticated."

# 2. Valkey (State) Test
log "\n2. Testing Valkey (State)..."
VS_PASS=$(kubectl get secret k3han-redis-secrets -n "$NAMESPACE" -o jsonpath="{.data.redis-password}" | base64 --decode)

PONG=$(kubectl exec -n "$NAMESPACE" valkey-state-0 -- valkey-cli -a "$VS_PASS" PING | tr -d '[:space:]')
if [ "$PONG" == "PONG" ]; then
    log "SUCCESS: Valkey State authenticated (PONG received)."
else
    error "FAIL: Valkey State authentication failed."
    exit 1
fi

# 3. Valkey (Cache) Test
log "\n3. Testing Valkey (Cache)..."
VC_PASS=$(kubectl get secret safezone-cache-secrets -n "$NAMESPACE" -o jsonpath="{.data.redis-password}" | base64 --decode)

PONG=$(kubectl exec -n "$NAMESPACE" valkey-cache-0 -- valkey-cli -a "$VC_PASS" PING | tr -d '[:space:]')
if [ "$PONG" == "PONG" ]; then
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

log "\n--- Infrastructure Smoke Test Completed ---"

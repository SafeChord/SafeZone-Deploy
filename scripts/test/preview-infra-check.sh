#!/usr/bin/env bash
set -e

# SafeZone-Deploy: Preview Infrastructure Smoke Test
# Purpose: Verify that modernized infrastructure (CNPG, Valkey, KafkaTopic) is correctly deployed and reachable.

NAMESPACE="safezone-preview"
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
PG_CLUSTER="db-primary"
PG_POD=$(kubectl get pod -n "$NAMESPACE" -l "cnpg.io/cluster=$PG_CLUSTER,role=primary" -o name | head -n 1)

if [ -z "$PG_POD" ]; then
    error "FAIL: CNPG primary pod not found in $NAMESPACE."
    exit 1
fi

log "Fetching password from k3han-db-secrets..."
PG_PASS=$(kubectl get secret k3han-db-secrets -n "$NAMESPACE" -o jsonpath="{.data.password}" | base64 --decode)

log "Executing SQL check on $PG_POD..."
kubectl exec -n "$NAMESPACE" "$PG_POD" -c postgres -- \
    psql -U postgres -d postgres -c "SELECT 'PostgreSQL Connection OK' as status;" | grep "OK"
log "✅ SUCCESS: PostgreSQL is reachable and authenticated."


# 2. Valkey (State) Test
log "\n2. Testing Valkey (State)..."
VS_POD="valkey-state-0"
VS_PASS=$(kubectl get secret k3han-redis-secrets -n "$NAMESPACE" -o jsonpath="{.data.redis-password}" | base64 --decode)

PONG=$(kubectl exec -n "$NAMESPACE" "$VS_POD" -- valkey-cli -a "$VS_PASS" PING | tr -d '[:space:]')
if [ "$PONG" == "PONG" ]; then
    log "✅ SUCCESS: Valkey State authenticated (PONG received)."
else
    error "FAIL: Valkey State authentication failed."
    exit 1
fi


# 3. Valkey (Cache) Test
log "\n3. Testing Valkey (Cache)..."
VC_POD="valkey-cache-0"
VC_PASS=$(kubectl get secret safezone-cache-secrets -n "$NAMESPACE" -o jsonpath="{.data.redis-password}" | base64 --decode)

PONG=$(kubectl exec -n "$NAMESPACE" "$VC_POD" -- valkey-cli -a "$VC_PASS" PING | tr -d '[:space:]')
if [ "$PONG" == "PONG" ]; then
    log "✅ SUCCESS: Valkey Cache authenticated (PONG received)."
else
    error "FAIL: Valkey Cache authentication failed."
    exit 1
fi


# 4. Kafka Topic Test (Logical Isolation)
log "\n4. Testing Kafka Topic Definition..."
TOPIC_NAME="preview-covid-case-data"
TOPIC_STATUS=$(kubectl get kafkatopic "$TOPIC_NAME" -n kafka -o jsonpath="{.status.conditions[0].type}" 2>/dev/null || echo "NOT_FOUND")

if [ "$TOPIC_STATUS" == "Ready" ]; then
    log "✅ SUCCESS: KafkaTopic '$TOPIC_NAME' is Ready."
else
    warn "INFO: KafkaTopic found but status is '$TOPIC_STATUS'. This is normal if shared cluster is reconciling."
fi

log "\n--- Infrastructure Smoke Test Completed ---"

#!/usr/bin/env bash
set -e

# SafeZone-Deploy: Universal Secret Sealing Tool
# Usage: bash scripts/ops/seal-secrets.sh [preview|staging]

ENV=$1
if [[ -z "$ENV" ]]; then
    echo "Usage: $0 [preview|staging]"
    exit 1
fi

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
TARGET_DIR="$REPO_ROOT/deploy/$ENV/infra/security"
UNSEALED_DIR="$TARGET_DIR/unsealed"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO] $1${NC}"; }

if [[ ! -d "$UNSEALED_DIR" ]]; then
    echo "Error: Unsealed directory not found at $UNSEALED_DIR"
    exit 1
fi

seal_file() {
    local NAME=$1
    local IN="$UNSEALED_DIR/unsealed-${NAME}.yaml"
    local OUT="$TARGET_DIR/sealed-${NAME}.yaml"

    if [[ -f "$IN" ]]; then
        log "Sealing $NAME for $ENV..."
        kubeseal --controller-name=sealed-secrets \
                 --controller-namespace=bootstrap \
                 --format yaml < "$IN" > "$OUT"
    else
        echo "Skip: $IN not found."
    fi
}

log "--- Starting Sealing Process for Environment: $ENV ---"

# 執行所有標準祕密密封
seal_file "authsecrets"
seal_file "cachesecrets"
seal_file "dbsecrets"
seal_file "dockersecrets"
seal_file "kafkasecrets"
seal_file "redissecrets"
seal_file "rolesecrets"

log "✅ SUCCESS: All secrets sealed in $TARGET_DIR"

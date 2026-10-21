#!/usr/bin/env bash
# Run the validation floor (F1-F7) against one environment and, with --soak, the soak checks
# (S1-S5) over the window since <start>. Read-only: it changes nothing in the cluster or on GitHub.
#
# Usage: verify-app.sh <preview|staging> [--soak <start>] [--tag <tag>]
#   --soak <start>  soak start, in any form `date -d` reads (e.g. '2026-10-21 10:14 +08:00')
#   --tag <tag>     the image tag under validation; default: from the env's single open
#                   TAG_ISSUE_LABEL issue (`release: v0.3.8` -> 0.3.8, `freight: <tag>` -> <tag>)
#
# Output: one tab-separated line per check, `PASS|FAIL|REPORT <id> <observed> <expected>`;
# lines starting with `#` are context. Exit 1 when a gating check fails, 2 on bad input.
# Pass conditions: harness .claude/validation/floor.md (F) and .claude/skills/validate-soak (S).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$SCRIPT_DIR/../../helm-charts"

REPO="SafeChord/SafeZone-Deploy"
IMAGE_PREFIX="ghcr.io/rebodutch/safezone-"
FROZEN_IMAGE="ghcr.io/rebodutch/safezone-dashboard"  # legacy exhibit, keeps its own tag
SEED_CITIES=22
PROM="http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
export LOKI_ADDR="${LOKI_ADDR:-http://loki.loki.svc.cluster.local:3100}"
KAFKA_POD="k3han-cluster-dual-role-0"
CONSUMER_GROUP="safezone-worker-group"
CURL=(curl -s --max-time 30)

die() { echo "verify-app: $1" >&2; exit 2; }

ENV="${1:-}"
[ "$ENV" = preview ] || [ "$ENV" = staging ] || die "usage: verify-app.sh <preview|staging> [--soak <start>] [--tag <tag>]"
shift
SOAK_START="" TAG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --soak) SOAK_START="${2:-}"; shift 2 || die "--soak needs a value" ;;
    --tag) TAG="${2:-}"; shift 2 || die "--tag needs a value" ;;
    *) die "unknown argument: $1" ;;
  esac
done
source "$SCRIPT_DIR/$ENV/env.sh"

# The external host is the chart's route.host for this env.
HOST=$(awk '/^route:/ { r = 1; next } /^[^ #]/ { r = 0 } r && $1 == "host:" { print $2 }' \
  "$CHART_DIR/safezone-foundation/values-$ENV.yaml")
[ -n "$HOST" ] || die "no route.host in safezone-foundation/values-$ENV.yaml"

if [ -z "$TAG" ]; then
  TITLES=$(gh issue list --repo "$REPO" --label "$TAG_ISSUE_LABEL" --state open --json title -q '.[].title') \
    || die "cannot list open '$TAG_ISSUE_LABEL' issues"
  [ "$(grep -c . <<<"$TITLES")" -eq 1 ] || die "expected one open '$TAG_ISSUE_LABEL' issue, found: ${TITLES:-none}; pass --tag"
  TAG="${TITLES#"$TAG_ISSUE_LABEL: "}"
  TAG="${TAG#v}"
fi

if [ -n "$SOAK_START" ]; then
  START_EPOCH=$(date -d "$SOAK_START" +%s 2>/dev/null) || die "cannot read soak start: $SOAK_START"
  NOW_EPOCH=$(date +%s)
  SECS=$((NOW_EPOCH - START_EPOCH))
  [ "$SECS" -gt 0 ] || die "soak start is in the future: $SOAK_START"
  START_UTC=$(date -u -d "@$START_EPOCH" +%FT%TZ)
  NOW_UTC=$(date -u -d "@$NOW_EPOCH" +%FT%TZ)
fi

FAILED=0
emit() { # <PASS|FAIL|REPORT> <id> <observed> <expected>
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
  [ "$1" = FAIL ] && FAILED=1
  return 0
}
gate() { # <id> <ok: 0 or 1> <observed> <expected>
  if [ "$2" = 1 ]; then emit PASS "$1" "$3" "$4"; else emit FAIL "$1" "$3" "$4"; fi
}
oneline() { tr '\n' ',' | sed 's/,$//'; }

echo "# env=$ENV ns=$NAMESPACE host=$HOST tag=$TAG"
[ -n "$SOAK_START" ] && echo "# soak window $START_UTC -> $NOW_UTC ($((SECS / 3600)) h)"

# This env's Applications: the app layer by name, the infra layer by label.
APPS=$(kubectl get applications -n argocd -o json | jq -c --arg p "$APP_PREFIX" \
  --arg lk "${INFRA_LABEL%%=*}" --arg lv "${INFRA_LABEL#*=}" \
  '[.items[] | select((.metadata.name | startswith($p)) or .metadata.labels[$lk] == $lv)]') || APPS=""

# --- F1 · Live images ---
IMAGES=$(kubectl get pods -n "$NAMESPACE" \
  -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' | sort -u) || IMAGES=""
IN_SCOPE=$(grep "^$IMAGE_PREFIX" <<<"$IMAGES" | grep -v "^$FROZEN_IMAGE:")
OFF_TAG=$(grep -vE ":${TAG//./\\.}\$" <<<"$IN_SCOPE" | grep .)
if [ -z "$IN_SCOPE" ]; then
  gate F1 0 "no $IMAGE_PREFIX* image found" "all at $TAG"
elif [ -n "$OFF_TAG" ]; then
  gate F1 0 "off tag: $(oneline <<<"$OFF_TAG")" "all at $TAG"
else
  gate F1 1 "$(grep -c . <<<"$IN_SCOPE") images at $TAG" "all at $TAG"
fi

# --- F2 · ArgoCD Applications ---
if [ -z "$APPS" ] || [ "$(jq length <<<"$APPS")" -eq 0 ]; then
  gate F2 0 "no Application found" "all Synced/Healthy"
else
  BAD=$(jq -r '.[] | select(.status.sync.status != "Synced" or .status.health.status != "Healthy")
    | "\(.metadata.name)=\(.status.sync.status)/\(.status.health.status)"' <<<"$APPS")
  N=$(jq length <<<"$APPS")
  if [ -n "$BAD" ]; then gate F2 0 "$(oneline <<<"$BAD")" "all $N Synced/Healthy"
  else gate F2 1 "$N Synced/Healthy" "all $N Synced/Healthy"; fi
fi

# The deploy run F3 and F4 measure against: the latest successful init-deploy on the branch the
# app layer tracks.
BRANCH=$(jq -r --arg p "$APP_PREFIX" '.[] | select(.metadata.name | startswith($p)) | .spec.source.targetRevision' \
  <<<"${APPS:-[]}" | sort -u)
RUN_ID="" RUN_SHA="" RUN_AT="" HEAD="" SMOKE=""
if [ "$(grep -c . <<<"$BRANCH")" -eq 1 ]; then
  IFS=$'\t' read -r RUN_ID RUN_SHA RUN_AT < <(gh run list --repo "$REPO" --workflow init-deploy.yml \
    --branch "$BRANCH" --status success --limit 1 --json databaseId,headSha,updatedAt \
    -q '.[0] | [.databaseId, .headSha, .updatedAt] | @tsv' 2>/dev/null)
  HEAD=$(gh api "repos/$REPO/branches/$BRANCH" -q .commit.sha 2>/dev/null)
  [ -n "$RUN_ID" ] && SMOKE=$(gh run view "$RUN_ID" --repo "$REPO" --json jobs \
    -q '.jobs[].steps[] | select(.name=="Wait for smoke job (hard gate)") | .conclusion' 2>/dev/null)
fi

# --- F3 · Pods ---
PODS=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Succeeded \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{range .status.containerStatuses[*]}{.ready}{","}{.lastState.terminated.finishedAt}{" "}{end}{"\n"}{end}') || PODS=""
BAD=$(awk -F'\t' -v at="$RUN_AT" '
  { ok = ($2 == "Running"); n = split($3, cs, " "); if (n == 0) ok = 0
    for (i = 1; i <= n; i++) { split(cs[i], f, ","); if (f[1] != "true" || (f[2] != "" && !(f[2] < at))) ok = 0 }
    if (!ok) print $1 }' <<<"$PODS")
EXPECT="Running/Ready, restarts before deploy run ${RUN_AT:-?}"
if [ -z "$PODS" ]; then gate F3 0 "no pod found" "$EXPECT"
elif [ -n "$BAD" ]; then gate F3 0 "not ready or restarted after the deploy: $(oneline <<<"$BAD")" "$EXPECT"
else gate F3 1 "$(grep -c . <<<"$PODS") pods" "$EXPECT"; fi

# --- F4 · Smoke gate of the deploy ---
EXPECT="run at ${BRANCH:-?} head ${HEAD:0:7}, smoke success"
if [ "$(grep -c . <<<"$BRANCH")" -ne 1 ]; then
  gate F4 0 "app layer tracks branches: $(oneline <<<"${BRANCH:-none}")" "one branch"
elif [ -z "$RUN_ID" ] || [ -z "$HEAD" ]; then
  gate F4 0 "no successful init-deploy run or branch head on $BRANCH" "$EXPECT"
else
  OK=0; [ "$RUN_SHA" = "$HEAD" ] && [ "$SMOKE" = success ] && OK=1
  gate F4 "$OK" "run $RUN_ID at ${RUN_SHA:0:7}, smoke ${SMOKE:-none}" "$EXPECT"
fi

# --- F5 · Seed data ---
DB_POD=$(kubectl get pod -n "$CNPG_CLUSTER_NS" -l "cnpg.io/cluster=$CNPG_CLUSTER,cnpg.io/instanceRole=primary" \
  -o name 2>/dev/null | head -n 1)
CITIES=""
[ -n "$DB_POD" ] && CITIES=$(kubectl exec -n "$CNPG_CLUSTER_NS" "$DB_POD" -c postgres -- \
  psql -U postgres -d safezone -tAc "SELECT COUNT(*) FROM public.cities;" 2>/dev/null)
OK=0; [ "$CITIES" = "$SEED_CITIES" ] && OK=1
gate F5 "$OK" "cities=${CITIES:-none}" "cities=$SEED_CITIES"

# --- F6 · ClientSettingsPolicy ---
ACCEPTED=$(kubectl get clientsettingspolicy safezone-dashboard -n "$NAMESPACE" \
  -o jsonpath='{.status.ancestors[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)
OK=0; [ "$ACCEPTED" = True ] && OK=1
gate F6 "$OK" "Accepted=${ACCEPTED:-none}" "Accepted=True"

# --- F7 · External probes ---
H="https://$HOST"
status_location() { # <url> -> "<status> <location>"
  "${CURL[@]}" -I "$1" | tr -d '\r' | awk 'NR == 1 { s = $2 } tolower($1) == "location:" { l = $2 } END { print s, l }'
}
read -r CODE LOC < <(status_location "$H/dashboard")
FOLLOWED=$("${CURL[@]}" -L -o /dev/null -w '%{http_code} %{num_redirects}' "$H/dashboard")
OK=0; [ "$CODE" = 301 ] && [ "$LOC" = /dashboard/ ] && [ "$FOLLOWED" = "200 1" ] && OK=1
gate F7.1 "$OK" "/dashboard $CODE location=${LOC:-none}, followed $FOLLOWED" "301 location=/dashboard/, followed 200 1"

CODE=$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$H/dashboard-classic/")
OK=0; [ "$CODE" = 200 ] && OK=1
gate F7.2 "$OK" "/dashboard-classic/ $CODE" "200"

C1=$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$H/dashboard/api/health")
C2=$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$H/dashboard/time/now")
OK=0; [ "$C1" = 200 ] && [ "$C2" = 200 ] && OK=1
gate F7.3 "$OK" "/dashboard/api/health $C1, /dashboard/time/now $C2" "200, 200"

# A 400 or 415 means the 2 MB body reached the app; 000 means no answer at all.
CODE=$(head -c 2000000 /dev/zero | tr '\0' x | "${CURL[@]}" -o /dev/null -w '%{http_code}' \
  -X POST --data-binary @- "$H/dashboard-classic/_dash-update-component")
OK=0; [ "$CODE" != 413 ] && [ "$CODE" != 000 ] && OK=1
gate F7.4 "$OK" "big-POST $CODE" "not 413"

read -r CODE LOC < <(status_location "http://$HOST/dashboard/")
OK=0; [ "$CODE" = 301 ] && [[ "$LOC" == https://* ]] && OK=1
gate F7.5 "$OK" "http:// $CODE location=${LOC:-none}" "301 to https://"

if [ -n "$SOAK_START" ]; then
  prom() { # <query> -> one "pod/container" line per series; fails on a query error
    local out
    out=$("${CURL[@]}" -f "$PROM/api/v1/query" --data-urlencode "query=$1") || return 1
    jq -e '.status == "success"' <<<"$out" >/dev/null || return 1
    jq -r '.data.result[] | "\(.metric.pod)/\(.metric.container)"' <<<"$out"
  }

  # --- S1 · Restarts over the window ---
  if RESTARTS=$(prom "sum by (pod, container) (increase(kube_pod_container_status_restarts_total{namespace=\"$NAMESPACE\"}[${SECS}s])) > 0") \
    && OOM=$(prom "max_over_time(kube_pod_container_status_last_terminated_reason{namespace=\"$NAMESPACE\",reason=\"OOMKilled\"}[${SECS}s]) > 0"); then
    OK=0; [ -z "$RESTARTS$OOM" ] && OK=1
    gate S1 "$OK" "restarts: $(oneline <<<"${RESTARTS:-none}"); OOMKilled: $(oneline <<<"${OOM:-none}")" "none"
  else
    gate S1 0 "Prometheus query failed" "none"
  fi

  # --- S2 · No sync during the soak ---
  if [ -z "$APPS" ]; then
    gate S2 0 "no Application found" "every last sync before $START_UTC"
  else
    LATE=$(jq -r --arg s "$START_UTC" '.[] | select((.status.operationState.finishedAt // "") > $s)
      | "\(.metadata.name)@\(.status.operationState.finishedAt)"' <<<"$APPS")
    OK=0; [ -z "$LATE" ] && OK=1
    gate S2 "$OK" "synced since: $(oneline <<<"${LATE:-none}")" "every last sync before $START_UTC"
  fi

  # --- S3 · Dashboard 5xx over the window ---
  LOKI_5XX='{namespace="nginx-gateway", pod=~"public-gateway-nginx.*"} | json | line_format "{{.message}}" | pattern `<_> - - <_> "<method> <path> <_>" <status> <_>` | path =~ `/dashboard.*` | status =~ `5..`'
  if LINES=$(logcli query --quiet --from="$START_UTC" --to="$NOW_UTC" --limit=200 -o raw "$LOKI_5XX" 2>/dev/null); then
    WINDOW="Loki"
  else
    # Loki unreachable: the gateway pod's own logs, which may not reach back to the start.
    GW=$(kubectl get pods -n nginx-gateway -o name | grep public | head -n 1)
    LINES=$(kubectl logs "$GW" -n nginx-gateway -c nginx --since-time="$START_UTC" | grep '/dashboard' | grep -E '" 5[0-9][0-9] ')
    WINDOW="pod logs, partial"
  fi
  OK=0; [ -z "$LINES" ] && OK=1
  gate S3 "$OK" "$(grep -c . <<<"$LINES") 5xx lines ($WINDOW)" "0"

  # --- S4 · Worker ERROR logs over the window ---
  COUNT=$(logcli instant-query --quiet \
    "sum(count_over_time({namespace=\"$NAMESPACE\", container=\"worker\"} | json | level=\"error\" [${SECS}s]))" 2>/dev/null \
    | jq -r '.[0].value[1] // "0"') || COUNT="query failed"
  emit REPORT S4 "${COUNT:-query failed} ERROR lines" "no threshold"
  logcli query --quiet --from="$START_UTC" --to="$NOW_UTC" --limit=2000 -o raw \
    "{namespace=\"$NAMESPACE\", container=\"worker\"} | json | level=\"error\" | line_format \"{{.error}}\"" 2>/dev/null \
    | sort | uniq -c | sort -rn | sed 's/^/#   S4 /'

  # --- S5 · Consumer lag now ---
  TOPIC=$(kubectl get kafkatopic "$KAFKA_TOPIC" -n "$KAFKA_TOPIC_NS" -o jsonpath='{.spec.topicName}' 2>/dev/null)
  LAG=$(kubectl exec -n "$KAFKA_TOPIC_NS" "$KAFKA_POD" -- /opt/kafka/bin/kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 --describe --group "$CONSUMER_GROUP" 2>/dev/null \
    | awk -v t="${TOPIC:-?}" '$2 == "TOPIC" { for (i = 1; i <= NF; i++) c[$i] = i; next }
        c["TOPIC"] && $c["TOPIC"] == t { printf "p%s=%s\n", $c["PARTITION"], $c["LAG"] }' | sort -V | oneline)
  emit REPORT S5 "${TOPIC:-?}: ${LAG:-query failed}" "no threshold"
fi

exit "$FAILED"

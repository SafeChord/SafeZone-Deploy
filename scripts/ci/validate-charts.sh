#!/usr/bin/env bash
# Validate the Helm charts of one environment the way ArgoCD renders them: parse
# deploy/<env>/app/*.yaml and lint and render each Application's chart with the exact
# value files and release name it names.
#
# Usage: validate-charts.sh <preview|staging>
#
# Run by .github/workflows/pr-checks.yml on PRs into staging and preview/<ver>; also safe to
# run locally from a clean checkout (it builds the charts' file:// dependencies in place).
# Exit 1 when any chart fails, 2 on bad input.

set -euo pipefail

ENV="${1:-}"
case "$ENV" in
  staging|preview) ;;
  *)
    echo "usage: validate-charts.sh <preview|staging>" >&2
    exit 2
    ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$REPO_ROOT/deploy/$ENV/app"
echo "[validate-charts] Environment '$ENV': validating charts from $APP_DIR ..."

# Extract (chart_path, release_name, values_file) triples from all Application manifests
# Output format: "<chart_path>|<release_name>|<values_file>" one per line
TRIPLES="$(python3 - "$APP_DIR" <<'EOF'
import sys, os, yaml, glob

app_dir = sys.argv[1]
for fpath in sorted(glob.glob(os.path.join(app_dir, "*.yaml"))):
    with open(fpath) as f:
        doc = yaml.safe_load(f)
    try:
        source = doc["spec"]["source"]
        chart_path = source["path"]
        helm = source.get("helm", {})
        release = helm.get("releaseName") or os.path.basename(chart_path)
        for vf in helm.get("valueFiles", []):
            print(f"{chart_path}|{release}|{vf}")
    except (KeyError, TypeError):
        pass
EOF
)"

if [[ -z "$TRIPLES" ]]; then
  echo "[validate-charts] No Helm Application pairs found — check $APP_DIR"
  exit 1
fi

ERRORS=0
DEP_BUILT=()
DEP_FAILED=()

while IFS='|' read -r CHART_PATH RELEASE VALUES_FILE; do
  CHART_DIR="$REPO_ROOT/$CHART_PATH"
  CHART_NAME="$(basename "$CHART_DIR")"
  VALUES_PATH="$CHART_DIR/$VALUES_FILE"

  # Run helm dependency build once per chart (local file:// deps need packaging)
  if [[ " ${DEP_BUILT[*]} " != *" ${CHART_DIR} "* ]]; then
    echo ""
    echo "── $CHART_NAME ──"
    DEP_BUILT+=("$CHART_DIR")
    if ! DEP_OUT=$(helm dependency build "$CHART_DIR" 2>&1); then
      echo "  [FAIL] helm dependency build"
      echo "$DEP_OUT" | sed 's/^/         /'
      ERRORS=$((ERRORS + 1))
      DEP_FAILED+=("$CHART_DIR")
    fi
  fi

  # A chart whose dependencies did not build cannot render with any values file
  if [[ " ${DEP_FAILED[*]} " == *" ${CHART_DIR} "* ]]; then
    echo "  [SKIP] $VALUES_FILE (dependencies did not build)"
    continue
  fi

  # Validate values file exists
  if [[ ! -f "$VALUES_PATH" ]]; then
    echo "  [FAIL] values file not found: $VALUES_FILE"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Lint with actual values (validates schema against real values, not empty defaults)
  if LINT_OUT=$(helm lint "$CHART_DIR" --values "$VALUES_PATH" 2>&1); then
    echo "  [OK]   helm lint ($VALUES_FILE)"
  else
    echo "  [FAIL] helm lint ($VALUES_FILE)"
    echo "$LINT_OUT" | sed 's/^/         /'
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Template render
  if TEMPLATE_OUT=$(helm template "$RELEASE" "$CHART_DIR" --values "$VALUES_PATH" 2>&1); then
    echo "  [OK]   helm template ($VALUES_FILE)"
  else
    echo "  [FAIL] helm template ($VALUES_FILE)"
    echo "$TEMPLATE_OUT" | sed 's/^/         /'
    ERRORS=$((ERRORS + 1))
  fi
done <<< "$TRIPLES"

echo ""
if [[ $ERRORS -gt 0 ]]; then
  echo "[validate-charts] $ERRORS error(s) found."
  exit 1
fi

echo "[validate-charts] All charts valid."
exit 0

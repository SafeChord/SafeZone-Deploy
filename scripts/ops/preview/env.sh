#!/usr/bin/env bash
# Sourced by the scripts beside it and by verify-app.sh, which use these variables;
# ShellCheck lints each file alone, so it reports every one as unused here.
# shellcheck disable=SC2034
# Preview environment configuration

NAMESPACE="safezone-preview"
APPSET_NAME="safezone-preview-infra-stage"
APPSET_MANIFEST="deploy/preview/infra/application.yaml"
APP_DIR="deploy/preview/app"
APP_PREFIX="safezone-preview-"  # app-layer Application names; the other env's may coexist

CNPG_CLUSTER="db-primary"
CNPG_CLUSTER_NS="$NAMESPACE"
KAFKA_TOPIC="preview-covid-case-data"
KAFKA_TOPIC_NS="kafka"

SIMULATOR_PVC="simulator-data-pvc"
SIMULATOR_PV="acer-local-1g-simulator-preview"

TAG_ISSUE_LABEL="freight"  # the open issue naming the tag under validation

INFRA_LABEL="safezone.io/stage=preview-infra"
APP_LABELS="app.kubernetes.io/instance in (safezone-foundation, safezone-core, safezone-ui, safezone-ops-schema, safezone-ops-cases, safezone-ops-smoke)"

FOUNDATION_DEPLOYS="safezone-cli-relay safezone-time-server"
CORE_DEPLOYS="safezone-analytics-api safezone-ingestor safezone-pandemic-simulator"
UI_DEPLOY="safezone-dashboard safezone-dashboard-v2"

VALKEY_STATEFULSETS="valkey-cache valkey-state"

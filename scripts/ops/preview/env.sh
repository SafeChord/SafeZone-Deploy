#!/usr/bin/env bash
# Preview environment configuration

NAMESPACE="safezone-preview"
APPSET_NAME="safezone-preview-infra-stage"
APPSET_MANIFEST="deploy/preview/infra/application.yaml"
APP_DIR="deploy/preview/app"

CNPG_CLUSTER="db-primary"
KAFKA_TOPIC="preview-covid-case-data"
KAFKA_TOPIC_NS="kafka"

SIMULATOR_PVC="simulator-data-pvc"
SIMULATOR_PV="acer-nfs-1g-1"

INFRA_LABEL="safezone.io/stage=preview-infra"
APP_LABELS="app.kubernetes.io/instance in (safezone-foundation, safezone-core, safezone-ui, safezone-seed-schema, safezone-seed-cases)"

FOUNDATION_DEPLOYS="safezone-cli-relay safezone-time-server"
CORE_DEPLOYS="safezone-analytics-api safezone-ingestor safezone-pandemic-simulator"
UI_DEPLOY="safezone-dashboard"

VALKEY_STATEFULSETS="valkey-cache valkey-state"

#!/usr/bin/env bash
# Staging environment configuration

NAMESPACE="safezone"
APPSET_NAME="safezone-staging-infra-stage"
APPSET_MANIFEST="deploy/staging/infra/application.yaml"
APP_DIR="deploy/staging/app"

# DB is Chorde platform service — no CNPG cluster in namespace
# Database CRD lives in database namespace
CNPG_DATABASE_NS="database"
CNPG_DATABASE_CR="safezone-db"

KAFKA_TOPIC="covid-case-data"
KAFKA_TOPIC_NS="kafka"

SIMULATOR_PVC="simulator-data-pvc"
SIMULATOR_PV="acer-nfs-1g-3"

INFRA_LABEL="safezone.io/stage=staging-infra"
APP_LABELS="app.kubernetes.io/instance in (safezone-foundation, safezone-core, safezone-ui, safezone-seed-schema, safezone-seed-cases)"

FOUNDATION_DEPLOYS="safezone-cli-relay safezone-time-server"
CORE_DEPLOYS="safezone-analytics-api safezone-ingestor safezone-pandemic-simulator"
UI_DEPLOY="safezone-dashboard"

# Only valkey-cache is self-managed; valkey-state is Chorde platform service
VALKEY_STATEFULSETS="valkey-cache"

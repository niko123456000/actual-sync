#!/usr/bin/env bash
# Setup script: list Redbark and Actual Budget account IDs so you can set
# ACCOUNT_MAPPING (or the add-on Configuration) before running the sync.
#
# Usage:
#   ./scripts/setup-account-ids.sh              # use .env in current dir
#   ./scripts/setup-account-ids.sh path/to.env
#   ./scripts/setup-account-ids.sh --redbark-only
#   ./scripts/setup-account-ids.sh --actual-only
#
# For Redbark you need: REDBARK_API_KEY
# For Actual you need:  ACTUAL_SERVER_URL, ACTUAL_PASSWORD, ACTUAL_BUDGET_ID

set -e

IMAGE="${ACTUAL_SYNC_IMAGE:-ghcr.io/redbark-co/actual-sync:latest}"
ENV_FILE="${1:-.env}"
REDBARK_ONLY=false
ACTUAL_ONLY=false

if [[ "$1" == "--redbark-only" ]]; then
  REDBARK_ONLY=true
  ENV_FILE="${2:-.env}"
elif [[ "$1" == "--actual-only" ]]; then
  ACTUAL_ONLY=true
  ENV_FILE="${2:-.env}"
elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
  head -20 "$0" | tail -18
  exit 0
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
  echo "Loaded env from $ENV_FILE"
else
  echo "No .env file at $ENV_FILE (optional for prompts)"
fi

run_redbark() {
  if [[ -z "${REDBARK_API_KEY:-}" ]]; then
    echo "REDBARK_API_KEY is not set. Set it in $ENV_FILE or export it, then run again."
    exit 1
  fi
  echo "--- Redbark accounts (use the IDs in ACCOUNT_MAPPING or add-on Config) ---"
  docker run --rm \
    -e REDBARK_API_KEY="$REDBARK_API_KEY" \
    -e "REDBARK_API_URL=${REDBARK_API_URL:-https://app.redbark.co}" \
    "$IMAGE" \
    --list-redbark-accounts
  echo "--- end Redbark ---"
}

run_actual() {
  for v in ACTUAL_SERVER_URL ACTUAL_PASSWORD ACTUAL_BUDGET_ID; do
    if [[ -z "${!v:-}" ]]; then
      echo "$v is not set. Set it in $ENV_FILE or export it, then run again."
      exit 1
    fi
  done
  echo "--- Actual Budget accounts (use the IDs in ACCOUNT_MAPPING or add-on Config) ---"
  docker run --rm \
    -e ACTUAL_SERVER_URL="$ACTUAL_SERVER_URL" \
    -e ACTUAL_PASSWORD="$ACTUAL_PASSWORD" \
    -e ACTUAL_BUDGET_ID="$ACTUAL_BUDGET_ID" \
    ${ACTUAL_ENCRYPTION_PASSWORD:+ -e ACTUAL_ENCRYPTION_PASSWORD="$ACTUAL_ENCRYPTION_PASSWORD"} \
    -v actual-sync-setup-data:/app/data \
    "$IMAGE" \
    --list-actual-accounts
  echo "--- end Actual ---"
}

if [[ "$REDBARK_ONLY" == true ]]; then
  run_redbark
elif [[ "$ACTUAL_ONLY" == true ]]; then
  run_actual
else
  run_redbark
  echo ""
  run_actual
  echo ""
  echo "Next: set ACCOUNT_MAPPING to redbark_id:actual_id pairs (comma-separated),"
  echo "e.g. ACCOUNT_MAPPING=rbk-abc:actual-uuid-1,rbk-def:actual-uuid-2"
  echo "For the Home Assistant add-on, put the same value in the Configuration tab."
fi

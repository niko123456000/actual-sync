#!/bin/sh
set -e

# Home Assistant mounts add-on options at /data/options.json
# We export them as env vars for the Node app (REDBARK_API_KEY, etc.)
if [ -f /data/options.json ]; then
  export REDBARK_API_KEY="$(jq -r '.redbark_api_key // empty' /data/options.json)"
  export REDBARK_API_URL="$(jq -r '.redbark_api_url // "https://app.redbark.co"' /data/options.json)"
  export ACTUAL_SERVER_URL="$(jq -r '.actual_server_url // empty' /data/options.json)"
  export ACTUAL_PASSWORD="$(jq -r '.actual_password // empty' /data/options.json)"
  export ACTUAL_BUDGET_ID="$(jq -r '.actual_budget_id // empty' /data/options.json)"
  export ACTUAL_ENCRYPTION_PASSWORD="$(jq -r '.actual_encryption_password // empty' /data/options.json)"
  export ACCOUNT_MAPPING="$(jq -r '.account_mapping // empty' /data/options.json)"
  export SYNC_DAYS="$(jq -r '.sync_days // "30"' /data/options.json)"
  export LOG_LEVEL="$(jq -r '.log_level // "info"' /data/options.json)"
  export DRY_RUN="$(jq -r 'if .dry_run == true then "true" else "false" end' /data/options.json)"
  SYNC_INTERVAL_HOURS="$(jq -r '.sync_interval_hours // 6' /data/options.json)"
fi

# Persistent dir for Actual's SQLite cache (survives add-on restarts)
mkdir -p /data/actual-cache
export ACTUAL_DATA_DIR=/data/actual-cache

# Default interval if not from options
: "${SYNC_INTERVAL_HOURS:=6}"
INTERVAL_SECS=$((SYNC_INTERVAL_HOURS * 3600))

echo "Redbark Actual Sync add-on started. Syncing every ${SYNC_INTERVAL_HOURS}h (${INTERVAL_SECS}s)."

while true; do
  if node /app/main.cjs; then
    echo "Sync completed successfully."
  else
    EXIT=$?
    echo "Sync exited with code $EXIT. Will retry after ${SYNC_INTERVAL_HOURS}h."
  fi
  sleep "$INTERVAL_SECS"
done

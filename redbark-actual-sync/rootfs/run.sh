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

# Apply navigator polyfill before any node run (fixes @actual-app/api in Node without rebuilding base image)
export NODE_OPTIONS="--require /polyfill-navigator.cjs ${NODE_OPTIONS:-}"

# Start web UI server (ingress) in the background
node /app/web-server.cjs &
WEB_PID=$!

# Default interval if not from options
: "${SYNC_INTERVAL_HOURS:=6}"
INTERVAL_SECS=$((SYNC_INTERVAL_HOURS * 3600))

# On first start, if account mapping is empty but we have credentials, list account IDs
# so the user can copy them from the Log tab into Configuration → Account mapping.
if [ -z "${ACCOUNT_MAPPING:-}" ]; then
  echo "Account mapping is empty. Listing account IDs (see below) so you can copy them into Configuration."
  if [ -n "$REDBARK_API_KEY" ]; then
    echo "--- Redbark accounts ---"
    node /app/main.cjs --list-redbark-accounts || true
  else
    echo "Add your Redbark API key in Configuration to list Redbark account IDs."
  fi
  if [ -n "$ACTUAL_SERVER_URL" ] && [ -n "$ACTUAL_PASSWORD" ] && [ -n "$ACTUAL_BUDGET_ID" ]; then
    echo "--- Actual Budget accounts ---"
    if ! node /app/main.cjs --list-actual-accounts; then
      echo "Actual account list failed (see error above). If you see 'navigator is not defined', update the add-on to the latest version and reinstall so the polyfill is applied."
    fi
  else
    # Say what's missing so the user knows why Actual accounts aren't listed
    _missing=""
    [ -z "$ACTUAL_SERVER_URL" ] && _missing="${_missing} server URL"
    [ -z "$ACTUAL_PASSWORD" ] && _missing="${_missing} password"
    [ -z "$ACTUAL_BUDGET_ID" ] && _missing="${_missing} budget ID"
    echo "Actual accounts: add the following in Configuration to list them:${_missing}. Budget ID is in Actual under Settings → Advanced."
  fi
  echo "Copy the IDs above into Configuration → Account mapping (redbark_id:actual_id, ...), then restart the add-on."
  echo ""
fi

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

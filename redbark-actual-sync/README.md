# Redbark Actual Sync — Home Assistant Add-on

Run [Redbark Actual Sync](https://github.com/redbark-co/actual-sync) as a Home Assistant add-on. The add-on runs continuously and syncs transactions from Redbark to Actual Budget on a schedule (default: every 6 hours).

All settings (Redbark API key, Actual server URL, account mapping, etc.) are presented on the add-on’s **Configuration** tab in Home Assistant. After installing the add-on, open it and go to the **Configuration** tab to enter your values; no environment variables or YAML are required.

**Web UI (ingress):** When the add-on is running, use **Open Web UI** (or the add-on’s **Web UI** link) to open the account-mapping page in your browser. It loads your Redbark and Actual accounts from the add-on and lets you pair them with dropdowns; then copy the generated mapping string into **Configuration → Account mapping** and save.

**First-time setup (no Docker needed):** If you add your Redbark API key and Actual server URL, password, and budget ID but leave **Account mapping** empty, the add-on will list your Redbark and Actual account IDs in the **Log** tab when it starts. Copy those IDs into **Account mapping** as `redbark_id:actual_id` pairs (comma-separated), then restart the add-on. If you see an error under "Actual Budget accounts" (e.g. `navigator is not defined`) instead of account names, update the add-on to the latest version and reinstall so the add-on includes the navigator polyfill.

## Installation

### Add this repository

1. In Home Assistant, go to **Settings → Add-ons → Add-on store**.
2. Click the **⋮** (top right) → **Repositories**.
3. Add: `https://github.com/redbark-co/actual-sync` (or your fork).
4. Refresh; **Redbark Actual Sync** should appear. Install and start it.

### Local add-on (copy into config)

1. Copy the `redbark-actual-sync` folder into your config (e.g. `config/addons/redbark-actual-sync/`) or add a [custom add-on source](https://www.home-assistant.io/common-tasks/os#installing-a-custom-add-on) that points to a path containing this folder.
2. Restart the Add-on store if needed; install and start the add-on.

## Configuration

Configure the add-on in **Settings → Add-ons → Redbark Actual Sync → Configuration**. Every option below is shown as a form field there; fill in the required ones and adjust optional ones as needed.

| Option | Required | Default | Description |
|--------|----------|--------|-------------|
| **Redbark API key** | Yes | — | Your Redbark API key (`rbk_live_...` from Redbark → Settings → API Keys). |
| **Actual server URL** | Yes | — | URL of your Actual Budget server (e.g. `http://actual:5006` or `http://192.168.1.10:5006`). |
| **Actual password** | Yes | — | Actual Budget server password. |
| **Actual budget ID** | Yes | — | Budget sync ID from Actual (Settings → Advanced). |
| **Account mapping** | Yes | — | Comma-separated `redbark_id:actual_id` pairs. |
| **Sync days** | No | 30 | Number of days of history to sync. |
| **Sync interval (hours)** | No | 6 | How often to run the sync (in hours). |
| **Log level** | No | info | `debug`, `info`, `warn`, or `error`. |
| **Actual encryption password** | No | — | E2E encryption password if your Actual budget uses it. |
| **Dry run** | No | false | If true, only previews imports and does not write to Actual. |

## Finding IDs

**Easiest:** Start the add-on with Redbark and Actual credentials (and budget ID) set in Configuration, then open **Open Web UI**. The account-mapping page will fetch your accounts and let you build the mapping with dropdowns; copy the result into **Account mapping** and save.

**Alternative (CLI):** Before filling the **Account mapping** field, you need Redbark and Actual account IDs. From a machine with Docker and this repo (or the main [README](https://github.com/redbark-co/actual-sync#2-find-your-account-ids)):

1. Create a `.env` with `REDBARK_API_KEY` and (for Actual) `ACTUAL_SERVER_URL`, `ACTUAL_PASSWORD`, `ACTUAL_BUDGET_ID`.
2. Run the setup script: `./scripts/setup-account-ids.sh` — it runs `--list-redbark-accounts` and `--list-actual-accounts` and prints the IDs to copy into the add-on **Account mapping** field.

Alternatively, run the same Docker commands manually (see main repo README) or get IDs from the Redbark dashboard and the Actual account URL in the web UI.

## Network

If Actual Budget runs in another container or on another host, use a URL that resolves from the add-on (e.g. `http://actual:5006` for a container named `actual`, or the host’s IP/hostname).

## Data

The add-on keeps Actual’s local cache in its persistent storage (`/data/actual-cache`). No extra volumes are required.

## Logs

Use the add-on’s **Log** tab to see sync runs and any errors.

## Troubleshooting

**`navigator is not defined`** — The add-on applies a polyfill automatically (loaded via `NODE_OPTIONS --require` before the app runs). Update to the latest add-on version and reinstall so the add-on image includes `rootfs/polyfill-navigator.cjs`; no need to rebuild the base sync image.

**`Could not locate the bindings file` (better-sqlite3)** — The sync app’s base image must be built on a glibc Linux base. This repo’s **GitHub Actions** build that image on push to `main` and push to `ghcr.io/<your-username>/actual-sync:latest`. After you push, wait for the “Docker” job to finish, then reinstall/update the add-on so it uses the new image. No local Docker needed.

## Maintaining a fork and syncing with upstream

If you run a fork and want to pull updates from the original [Redbark Actual Sync](https://github.com/redbark-co/actual-sync) project, see [MAINTENANCE.md](../MAINTENANCE.md) in the repo root for how to add the upstream remote and merge updates, and how to keep the add-on on the latest sync version.

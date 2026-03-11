# Review: Redbark Destinations — Actual Budget

Review of the Redbark “Destinations – Actual Budget” doc against the [actual-sync](https://github.com/redbark-co/actual-sync) repo. Use this to align or update the published doc.

---

## What’s accurate

- **Positioning:** Correct that Actual Budget sync is a standalone Docker tool, not a destination in the Redbark dashboard.
- **Prerequisites:** Accurate (Actual server, Docker, Redbark account, API key).
- **Steps 1–7:** Match the tool’s flow. Docker commands, env vars, dry run, and run-for-real are correct.
- **Environment variables table:** Matches the app (including optional vars).
- **CLI flags:** Correct.
- **Docker run / Compose / CronJob:** Correct.
- **Deduplication, exit codes, troubleshooting, security:** All match the repo.

---

## Suggested additions

1. **Setup script (easier than raw Docker for IDs)**  
   After “Find your Redbark account IDs” you could add:

   > **Alternative:** From a clone of the repo, create a `.env` with `REDBARK_API_KEY` (and Actual vars if you have them), then run:
   > `./scripts/setup-account-ids.sh`
   > This runs both `--list-redbark-accounts` and `--list-actual-accounts` and prints the IDs in one go.

2. **Home Assistant add-on**  
   Add a short section, e.g.:

   > **Home Assistant:** You can run the sync as a Home Assistant add-on (no cron needed). Add the repo `https://github.com/redbark-co/actual-sync` in **Settings → Add-ons → Add-on store → Repositories**, install **Redbark Actual Sync**, and configure everything in the add-on **Configuration** tab. See the [add-on README](https://github.com/redbark-co/actual-sync/tree/main/redbark-actual-sync) for details.

3. **API version matching**  
   Optional one-liner in Troubleshooting or a “How it works” note:

   > The tool detects your Actual server version and, if needed, downloads a matching client; the first run may take a few seconds while it caches the client.

---

## Minor wording

- **Step 4:** “Map each Redbark account to an Actual Budget account” is clear; the `redbark_id:actual_id` format is correct.
- **Source code:** `github.com/redbark-co/actual-sync` is correct; you could add “(MIT)” if you mention the license.

---

## Log timestamps and “only after 1:45pm Sydney”

Add-on and Docker logs use **Unix milliseconds** (e.g. `"time":1773197263812`). To interpret them in Sydney time:

- **Format:** `time` in log lines is milliseconds since 1 Jan 1970 UTC.
- **Sydney:** Australia/Sydney is UTC+10 (AEST) or UTC+11 (AEDT). In March 2026, Sydney is on AEDT (UTC+11).
- **Example:** `1773197263812` → 2026-03-11 15:47:43 Sydney (AEDT).

**“Only consider logs after 1:45pm Sydney”:**

- For **support/debugging:** When reviewing logs, convert `time` to Sydney (e.g. with a script or an epoch converter set to Australia/Sydney) and ignore lines before 1:45pm Sydney on the relevant day.
- For **automation:** The add-on has no built-in “only run after 1:45pm Sydney” filter. To get that behaviour you can:
  - **Cron (Docker):** Run the container on a schedule that’s after 1:45pm Sydney (e.g. `0 14 * * *` in a timezone set to Australia/Sydney, or the equivalent in your TZ).
  - **Home Assistant:** Use an automation that starts the add-on or triggers a sync only after 1:45pm Sydney (e.g. time trigger 13:45 in Sydney).

If you want the add-on itself to refuse to sync before a configured “earliest run time” (e.g. 1:45pm Sydney), that would be a new feature (config option + check in `run.sh` or the Node app before starting the sync).

---

## Summary

- The Destinations doc is accurate; the main improvements are mentioning the **setup script** and the **Home Assistant add-on**, plus optional notes on API version matching and log timestamps.
- For “only after 1:45pm Sydney,” use scheduling (cron or HA automation) or a future “earliest run time” option in the add-on.

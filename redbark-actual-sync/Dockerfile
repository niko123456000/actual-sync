# Home Assistant add-on: runs Redbark Actual Sync on a schedule.
# Uses the image built by this repo's CI (GHCR). On your fork this is ghcr.io/<your-username>/actual-sync:latest.
FROM ghcr.io/niko123456000/actual-sync:latest

RUN apt-get update && apt-get install -y --no-install-recommends jq && rm -rf /var/lib/apt/lists/*

COPY rootfs/polyfill-navigator.cjs /polyfill-navigator.cjs
COPY rootfs/run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]

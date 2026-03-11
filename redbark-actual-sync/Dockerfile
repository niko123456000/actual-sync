# Home Assistant add-on: runs Redbark Actual Sync on a schedule.
# Uses the published image and adds a runner that reads /data/options.json.
FROM ghcr.io/redbark-co/actual-sync:latest

RUN apk add --no-cache jq

COPY rootfs/polyfill-navigator.cjs /polyfill-navigator.cjs
COPY rootfs/run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]

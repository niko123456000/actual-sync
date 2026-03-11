# Maintaining the Home Assistant Add-on and Syncing with Upstream

This document is for maintainers who want to keep the Home Assistant add-on in sync with the original [Redbark Actual Sync](https://github.com/redbark-co/actual-sync) project.

## Version bump (required for add-on store updates)

**Always bump the version** when you make user-facing or fix changes so the Home Assistant add-on store can offer an update. Update these three places to the same version (e.g. `0.1.4` → `0.1.5`):

1. **`package.json`** — `"version": "x.y.z"`
2. **`redbark-actual-sync/config.yaml`** — `version: "x.y.z"`
3. **`src/redbark-client.ts`** — User-Agent string: `redbark-actual-sync/x.y.z`

Then commit (e.g. `Bump version to x.y.z`) and push. Without a bump, the add-on store will not show a new version.

## Recommendation: Fork the Original Project

**Yes, you should fork the original project** if you want to:

- Ship the add-on from your own repo (e.g. your GitHub username/actual-sync).
- Inherit updates from the upstream sync app (bug fixes, new features) while keeping your add-on layer.

The add-on is **additive**: it only adds the `redbark-actual-sync/` folder and `repository.yaml` at the repo root. The rest of the repo stays aligned with upstream, so merging upstream is straightforward.

## One-time setup in your fork

1. **Fork** [redbark-co/actual-sync](https://github.com/redbark-co/actual-sync) on GitHub (or clone and push to your own repo).

2. **Add upstream as a remote** (so you can pull updates later):
   ```bash
   git remote add upstream https://github.com/redbark-co/actual-sync.git
   ```

3. If you forked after the add-on was added here, you’re done. If the add-on lives only in your fork, keep the add-on files in your fork and merge or rebase from upstream as below.

## Pulling updates from upstream

Whenever you want to pick up the latest sync app (and any other upstream changes):

```bash
git fetch upstream
git checkout main   # or your default branch
git merge upstream/main
```

Resolve any conflicts (they’re most likely in the add-on files if upstream ever adds similar content). Then push to your repo and, if you use the add-on store, users can update.

## How the add-on gets the “latest” sync app

You have two approaches:

### A. Use the published Docker image (current setup)

- The add-on’s `Dockerfile` uses `FROM ghcr.io/redbark-co/actual-sync:latest`.
- **Pros:** Simple; no build of the Node app in the add-on.
- **Cons:** The add-on only gets updates when upstream publishes a new image (e.g. `latest`). If you’re maintaining a fork and upstream doesn’t publish often, your fork’s add-on will still run whatever `latest` is at build time.

To “inherit” updates in this setup:

1. Merge from upstream as above.
2. If upstream released a new version, you can bump the add-on `version` in `redbark-actual-sync/config.yaml` and rebuild/reinstall the add-on so the new image is used.

### B. Build the sync app from source (for “always latest” in your fork)

The Supervisor builds add-ons with **build context = add-on directory only**, so it cannot see the rest of the repo. To build the sync app from source you have two options:

- **CI-built image:** In GitHub Actions (or similar), build from the **repo root**:  
  `docker build -f redbark-actual-sync/Dockerfile.build -t ghcr.io/yourname/actual-sync:latest .`  
  Push that image and point the add-on’s `Dockerfile` at it (e.g. `FROM ghcr.io/yourname/actual-sync:latest`), or use `image:` in `config.yaml` so the add-on uses the pre-built image instead of building. Then every merge from upstream and re-run of CI produces a new image with the latest sync code.

- **Local build from repo root:** For testing, from the repo root:  
  `docker build -f redbark-actual-sync/Dockerfile.build -t redbark-actual-sync .`  
  and run the container manually. This does not change how the add-on is built inside Home Assistant.

A `Dockerfile.build` that builds the app from the repo root (for CI or local use) can live in `redbark-actual-sync/` and expect to be run with context = repo root; it would build the Node app and add `run.sh` so the image is a drop-in replacement for `ghcr.io/redbark-co/actual-sync:latest`. If you add this, keep the current add-on `Dockerfile` (Option A) so the Supervisor can still build the add-on by layering `run.sh` + jq on top of the published or CI-built image.

## Summary

| Goal | Recommendation |
|------|----------------|
| Have your own add-on repo | Fork upstream and add the add-on (or keep it in your fork). |
| Get upstream fixes/features | Add `upstream` remote and run `git fetch upstream && git merge upstream/main` regularly. |
| Add-on uses latest sync code | Use Option A (upstream’s published image) or Option B (CI builds from repo root and you point the add-on at that image). |

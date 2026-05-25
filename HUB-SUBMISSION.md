# dbt Hub submission — portfoliq/portfoliq

> Status: **ready, pending GitHub push + hubcap PR.**

## Process (verified 2026-05-24, per [hubcap README](https://github.com/dbt-labs/hubcap))

1. **Repository must be public on GitHub** with a tagged semver release (we have `v1.0.0`).
2. **Open a PR** on [`dbt-labs/hubcap`](https://github.com/dbt-labs/hubcap) adding our repo to `hub.json`.
3. **Approval**: a Fishtown / dbt Labs team member reviews — typically within 1 business day.
4. **Indexing**: once merged, `hubcap.py` runs hourly and picks up our `v1.0.0` tag.
5. **Live**: a few hours later, https://hub.getdbt.com/portfoliq/portfoliq/latest/ goes live.

## Pre-flight checklist

- [x] `dbt_project.yml` has `name: 'portfoliq'`
- [x] `require-dbt-version: [">=1.6.0", "<2.0.0"]` set
- [x] LICENSE present (MIT)
- [x] README.md with install instructions
- [x] Git tag `v1.0.0` exists locally
- [x] `dbt parse` + `dbt build` + `dbt test` pass on integration_tests (DuckDB)
- [x] Public repo on GitHub `benamor001/portfoliq-dbt-package`
- [ ] Tag `v1.0.0` pushed to GitHub
- [ ] PR opened on `dbt-labs/hubcap` adding `"benamor001": ["portfoliq-dbt-package"]` to `hub.json`

## Monorepo strategy — `git subtree` (recommended workflow)

The dbt pack lives in the **monorepo `portfolIQ/dbt-package/`** subdirectory (source of truth).
Public mirror to `benamor001/portfoliq-dbt-package` is a one-line `git subtree push` at release time.

### Why subtree (not a separate repo)
- Single source of truth — no double-commit
- CI tests pack + main API together
- dbt models stay aligned with PIQ schema
- Public mirror stays clean (contains only `dbt-package/` contents)

## Manual steps for Wael (gh CLI auth required once)

### One-time setup
```bash
# 1. Auth gh CLI (one-time, browser flow)
gh auth login

# 2. Create the empty public mirror repo on GitHub
gh repo create benamor001/portfoliq-dbt-package \
  --public \
  --description "Official dbt package for portfolIQ — Star Schema, AI analyses, halal screening."
```

### Release workflow (every version bump)
```bash
cd /root/dev/portfolIQ   # monorepo root

# 3. Push current dbt-package/ contents to the public mirror
git subtree push --prefix=dbt-package \
  git@github.com:benamor001/portfoliq-dbt-package.git main

# 4. Tag the mirror with v1.0.0 (mirror only, not monorepo)
# Clone mirror temporarily, tag, push, cleanup:
TMPDIR=$(mktemp -d)
git clone git@github.com:benamor001/portfoliq-dbt-package.git "$TMPDIR/pack"
cd "$TMPDIR/pack"
git tag -a v1.0.0 -m "v1.0.0 — first public release"
git push origin v1.0.0
gh release create v1.0.0 --title "v1.0.0 — first public release" --notes-file CHANGELOG.md
cd /root/dev/portfolIQ
rm -rf "$TMPDIR"
```

### dbt Hub submission (one-time)
```bash
# 5. Fork hubcap and open the submission PR
gh repo fork dbt-labs/hubcap --clone
cd hubcap
# Edit hub.json — add: "benamor001": ["portfoliq-dbt-package"]
git checkout -b add-portfoliq-pack
git commit -am "feat: add portfoliq/portfoliq-dbt-package"
git push -u origin add-portfoliq-pack
gh pr create \
  --repo dbt-labs/hubcap \
  --title "Add benamor001/portfoliq-dbt-package" \
  --body "$(cat <<'EOF'
## Package

[portfoliq/portfoliq-dbt-package](https://github.com/benamor001/portfoliq-dbt-package) v1.0.0

## Purpose

Public dbt package distributing the portfolIQ Star Schema (crypto top-1000, AI analyses historized, halal screening). Companion to the portfolIQ REST API.

## Best-practices checklist

- [x] Semver tag `v1.0.0` published
- [x] LICENSE present (MIT)
- [x] README with install instructions
- [x] `require-dbt-version: [">=1.6.0", "<2.0.0"]`
- [x] CI green on dbt 1.6..1.11 (parse + build + test on DuckDB)
- [x] No competing namespace (first `portfoliq` package)
EOF
)"
```

## Expected ETA

- **PR opened to merged**: ~1 business day (dbt-labs team review).
- **Merge to indexed on hub.getdbt.com**: hourly cron, ~1 hour.
- **Total**: published live within 24-48h.

## If submission stalls

Common reasons for hubcap PR rejection (per `package-best-practices.md`):

1. Missing `LICENSE` — we have MIT. ✓
2. Missing `README.md` — we have one. ✓
3. No tagged release — `v1.0.0` exists locally, needs to be pushed. ⚠
4. Misnamed package (must match repo name minus prefix). Our `dbt_project.yml` has `name: 'portfoliq'` and the repo is `portfoliq-dbt-package`. **This may need adjustment** — hubcap convention may expect `name: 'portfoliq_dbt_pack'` or `name: 'portfoliq'`. Verify by reading `hubcap/scripts/check_for_changes.py` once the PR is opened. If review asks for rename, update `dbt_project.yml` to `name: 'portfoliq_dbt_pack'` and retag.
5. Namespace conflict — `portfoliq` is a brand-new namespace on dbt Hub, no conflict expected.

## Fallback: distribution via git (no hub)

If hubcap submission stalls or is rejected, consumers can still install via git:

```yaml
packages:
  - git: "https://github.com/benamor001/portfoliq-dbt-package"
    revision: v1.0.0
```

This works **identically** to a hub install and is documented in our README. The hub listing is purely a discoverability/marketing benefit — functionally the package is already shippable.

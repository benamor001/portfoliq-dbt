# Publishing `portfoliq-dbt`

Manual steps for Wael to ship a new release of the package to a standalone
GitHub repo (and eventually dbt Hub).

> The `dbt-package/portfoliq/` directory in `finance-data-api` is the **source
> of truth**. The standalone repo (`portfoliq-dbt`) is a one-way mirror.

## Step 1 — Validate locally

From the package root:

```bash
cd ~/dev/portfolIQ/dbt-package/portfoliq
dbt deps                 # install dbt_utils
dbt parse                # syntax check, no DB connection needed
dbt seed --target dev    # if you have a local DB to test against
dbt run  --target dev
dbt test --target dev
```

A clean `dbt parse` is the minimum bar. The Sprint 90 Lane B handover
guarantees `dbt parse` passes.

## Step 2 — Create the standalone repo (one-time)

```bash
# Create empty repo on GitHub UI: github.com/benamor001/portfoliq-dbt
# Then locally:
cd /tmp
mkdir portfoliq-dbt && cd portfoliq-dbt
git init -b main
cp -r ~/dev/portfolIQ/dbt-package/portfoliq/. .
git add .
git commit -m "Initial release v0.1.0 — Sprint 89 Lane B marts"
git remote add origin git@github.com:benamor001/portfoliq-dbt.git
git push -u origin main
git tag v0.1.0
git push origin v0.1.0
```

## Step 3 — Sync subsequent versions

For each new version (bump `dbt_project.yml:version` + `CHANGELOG.md`):

```bash
cd /tmp/portfoliq-dbt
git pull
rsync -av --delete \
  --exclude='.git/' \
  --exclude='target/' \
  --exclude='dbt_packages/' \
  --exclude='logs/' \
  ~/dev/portfolIQ/dbt-package/portfoliq/ .
git add .
git commit -m "Release v0.2.0 — <summary>"
git tag v0.2.0
git push origin main
git push origin v0.2.0
```

## Step 4 — Smoke-test the published version

In a throwaway dbt project (e.g. `/tmp/smoke-test`):

```yaml
# packages.yml
packages:
  - git: "https://github.com/benamor001/portfoliq-dbt.git"
    revision: v0.1.0
```

```bash
dbt deps
dbt parse --select portfoliq
```

If `dbt parse` succeeds against a real consumer project, the release is good.

## Step 5 — dbt Hub submission (optional, after 1.0.0)

Hubcap automates Hub submissions. Wait until `1.0.0` (schema-frozen):

1. Fork `dbt-labs/hubcap`.
2. Add the package entry in `hub.json`.
3. Open a PR. dbt Labs reviews and merges.

See https://github.com/dbt-labs/hubcap for the current process.

---

## Versioning policy

- **0.x.y** — schema may break in minor versions. Pin a specific tag.
- **1.x.y** — schema stable; minor versions are additive only.
- Breaking changes always bump the major version.

The `revision:` in the consumer's `packages.yml` should be a tag (never `main`).

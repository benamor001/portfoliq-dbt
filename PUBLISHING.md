# Publishing portfoliq-dbt to GitHub and dbt Hub

This document describes the one-time setup and the repeatable publish procedure
for Wael (or any maintainer with push rights).

---

## Prerequisites

- Git access to `git@github.com:portfoliq/portfoliq-dbt.git`
- SSH key configured for the `portfoliq` GitHub organisation
- Working directory: root of the `finance-data-api` monorepo
- `make` installed

---

## Step 1 — Create the public GitHub repository (one-time)

1. Log into GitHub as the `portfoliq` organisation account.
2. Create a new **public** repository named `portfoliq-dbt`.
   - No README, no .gitignore, no license (we push everything from the subtree).
   - Description: "portfolIQ dbt pack — Star Schema models for crypto financial data"
3. Note the SSH URL: `git@github.com:portfoliq/portfoliq-dbt.git`

---

## Step 2 — Add the remote (one-time)

```bash
make init-dbt-pack-remote
```

Verify:

```bash
git remote -v
# should list origin-dbt-pack  git@github.com:portfoliq/portfoliq-dbt.git
```

---

## Step 3 — First publish

```bash
make publish-dbt-package
```

This runs `git subtree push --prefix=dbt-package origin-dbt-pack main`.

The first push may take a few minutes as git rewrites history for the subtree.

Verify on GitHub that the repository contains:
- `models/` (17 SQL files)
- `seeds/` (4 CSV reference files)
- `tests/` (custom generic tests)
- `macros/`
- `dbt_project.yml`, `packages.yml`, `profiles.yml.example`
- `LICENSE`, `NOTICE.md`, `README.md`, `CONTRIBUTING.md`
- `hub_metadata.yml`

---

## Step 4 — Subsequent publishes

Each time `dbt-package/` changes in the monorepo and those commits are merged to
`master`, run:

```bash
make publish-dbt-package
```

No additional setup needed after Step 2.

---

## Step 5 — Submit to dbt Hub (when ready for public listing)

dbt Hub (hub.getdbt.com) accepts packages from public GitHub repositories.

1. Ensure the GitHub repo is public and has at least one tag following semver:
   ```bash
   git -C . tag v0.1.0  # tag the monorepo commit after publish
   # then push the tag via: git push origin v0.1.0
   # the subtree already contains the version in dbt_project.yml
   ```
2. Submit via the dbt Hub web form at https://hub.getdbt.com/publish/ or open a
   PR to the `dbt-labs/hubcap` repository (the standard process).
3. Reference `hub_metadata.yml` for the required fields.

Note: dbt Hub review is a manual process maintained by dbt-labs. Listing is
subject to their acceptance criteria (public repo, valid dbt_project.yml, tests
present, documentation).

---

## Dry-run verification (no remote needed)

```bash
make -n publish-dbt-package
# Prints the git subtree command without executing it
```

---

## CI validation (no DB required)

The GitHub Actions workflow `.github/workflows/dbt-pack-ci.yml` runs automatically
on push/PR to paths matching `dbt-package/**`. It performs:
- `dbt deps`
- `dbt parse --vars '{portfoliq_enable_star: false}'`
- `dbt compile --vars '{portfoliq_enable_star: false}'`

No live database is required. The `portfoliq_enable_star: false` flag causes all
models to return empty sets without opening a connection.

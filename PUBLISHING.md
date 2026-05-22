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

## Pre-publish anti-leak verification

Run the automated check before any publish:

```bash
make pre-publish-check
```

This verifies the following conditions (all must pass):

- `dbt-package/dbt_packages/` is absent — third-party packages must not be bundled
  (verify `.gitignore` excludes `dbt_packages/`).
- `dbt-package/target/` is absent — compiled artifacts must not be pushed.
- `dbt-package/profiles.yml` (without `.example` suffix) is absent — no credentials
  in clear text; only `profiles.yml.example` is allowed.
- `dbt-package/.env` is absent — no environment secrets.
- `dbt-package/logs/` is absent — no dbt run logs.
- No `*.csv` files outside `dbt-package/seeds/` — the only CSVs allowed are the
  four reference seeds (`dim_chain`, `dim_event_type`, `dim_analysis_type`,
  `dim_tier`), which are code-only reference data, not third-party market data.
- `grep -rE '(password|secret|token|api_key|0x[a-fA-F0-9]{40})' dbt-package/`
  returns zero results (excluding known documentation placeholders such as
  `sql_user_xxxxxxxx`, `<from`, `example.com`).
- All SQL files in `examples/queries/` use only CTEs/snippets with no credentials
  embedded.

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

---

## Final Pre-Flight Checklist 2026-05-22

Run through every item before executing `make publish-dbt-package`. All 15 must
be green.

| # | Item | Status |
|---|------|--------|
| 1 | `dbt-package/LICENSE` present (ELv2) | OK |
| 2 | `dbt-package/NOTICE.md` present (7 clauses §9quinquies.7) | OK |
| 3 | `dbt-package/README.md` present — quickstart 5 min, links to `/docs/bi-package` | OK |
| 4 | `dbt-package/dbt_project.yml` version `0.1.0`, profile `portfoliq` | OK |
| 5 | `dbt-package/hub_metadata.yml` — name, version, license ELv2, adapters [postgres], docs URL `portfoliq.io/docs/bi-package` | OK — fixed T-341 |
| 6 | 17 SQL models (3 dims + 10 facts + 4 sats) | OK |
| 7 | 4 seeds (dim_chain, dim_event_type, dim_analysis_type, dim_tier) | OK |
| 8 | 125+ tests in `models/schema.yml` (239 test entries audited) | OK |
| 9 | 20 example queries in `dbt-package/examples/queries/` | OK |
| 10 | `dbt-package/CONTRIBUTING.md` present | OK |
| 11 | Makefile cibles `publish-dbt-package`, `init-dbt-pack-remote`, `pre-publish-check` | OK |
| 12 | `.github/workflows/dbt-pack-ci.yml` CI present and valid | OK |
| 13 | `profiles.yml` removed from git tracking — `git rm --cached` done T-341 | OK — fixed T-341 |
| 14 | `dbt parse` PASS (CI validates on push) | OK |
| 15 | Links to `/docs/bi-package` coherent post-Sprint 23 (README + hub_metadata) | OK — fixed T-341 |

Command to run when ready:

```bash
# 1. Automated anti-leak check
make pre-publish-check

# 2. Publish subtree to public repo
make publish-dbt-package
```

---

## Post-publication runbook

### A — GitHub repository setup (one-time, after first push)

1. Go to `https://github.com/portfoliq/portfoliq-dbt` → Settings → Topics.
   Add these topics: `dbt`, `crypto`, `dbt-package`, `star-schema`, `postgres`,
   `data-vault`, `timescaledb`, `finance`.
2. Add a repo description: "portfolIQ dbt pack — Star Schema models for crypto financial data".
3. Set the website URL to `https://portfoliq.io/docs/bi-package`.
4. Create a semver tag for the initial release:
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

### B — dbt Hub submission

Submit to the dbt Hub (hub.getdbt.com) after the GitHub repo has at least one
public tagged release (v0.1.0).

Standard process: open a PR on `dbt-labs/hubcap` adding the package entry, or
use the web form at `https://hub.getdbt.com/publish/`.

Fields to provide (from `hub_metadata.yml`):
- Package name: `portfoliq/portfoliq_dbt`
- Version: `0.1.0`
- License: ELv2
- Adapters: postgres
- Documentation: `https://portfoliq.io/docs/bi-package`
- Repository: `https://github.com/portfoliq/portfoliq-dbt`

dbt Hub review is manual and may take 1-4 weeks. Acceptance criteria: public
repo, valid `dbt_project.yml`, tests present, documentation link live.

### C — Show HN post template

```
Title: Show HN: portfoliq-dbt — open dbt package for crypto Star Schema (ELv2)

We built a dbt package that materializes a Star Schema (3 dims + 10 facts +
4 satellites) on top of crypto market data (CoinGecko, DeFiLlama, FRED, ECB,
on-chain BigQuery). Aimed at data engineers building fintech apps who want
analytics-ready models without reinventing the wheel.

- GitHub: https://github.com/portfoliq/portfoliq-dbt
- Docs: https://portfoliq.io/docs/bi-package
- 17 SQL models, 4 seeds, 125+ tests, 20 example queries
- Compatible with Power BI / Tableau / Metabase / Lightdash / Cube.dev
- License: Elastic License v2 (internal use free, SaaS resale restricted)

Not financial advice. Methodology disclosed.
```

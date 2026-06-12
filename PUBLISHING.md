# Publishing portfoliq-dbt to GitHub

This package is a **self-contained, standalone dbt package**. Publishing it is a plain
`git init` + push of the contents of `dbt-package/` to a new **public** GitHub repo,
then tagging `v0.2.0`. No monorepo subtree, no special tooling.

> Distribution channel is **git-install** (primary). A dbt Hub listing is optional and
> not guaranteed (ELv2 is non-OSI). See `HUB-SUBMISSION.md`.

---

## Prerequisites (Wael)

- A GitHub account (repo is under `benamor001`).
- `make` + `dbt` + `dbt-duckdb` installed locally (already present in this env).

---

## Step 0 — Validate locally (no remote, no DB needed)

```bash
cd dbt-package
make ci                 # installs the pack from a blank project + dbt parse → GREEN
make pre-publish-check  # anti-leak guard: no target/, dbt_packages/, profiles.yml, MIT, double project
```

Both must pass before pushing.

---

## Step 1 — Create the public repo (one-time, Wael)

Create a new **public** GitHub repo named `portfoliq-dbt` under your account/org.
No README / .gitignore / license from the GitHub UI — we push everything from here.

```bash
gh repo create benamor001/portfoliq-dbt --public \
  --description "portfolIQ dbt pack — Star Schema models for crypto financial data"
```

---

## Step 2 — Push the package contents (one-time, Wael)

`dbt-package/` is the publish root. Initialise a fresh git repo **inside it** (it has its
own `.gitignore` that already excludes `target/`, `dbt_packages/`, `logs/`, `.dbt/`,
`profiles.yml`) and push:

```bash
cd dbt-package
git init
git add .
git commit -m "feat: portfoliq-dbt v0.2.0 — crypto Star Schema consumer pack (ELv2)"
git branch -M main
git remote add origin git@github.com:benamor001/portfoliq-dbt.git
git push -u origin main
```

Verify on GitHub that the repo contains: `models/`, `seeds/`, `tests/`, `macros/`,
`integration_tests/`, `dbt_project.yml`, `packages.yml`, `profiles.yml.example`,
`LICENSE` (ELv2), `NOTICE.md`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`,
`hub_metadata.yml`. Confirm `profiles.yml` (no `.example`) is **absent**.

---

## Step 3 — Tag the release (one-time per version, Wael)

```bash
cd dbt-package
git tag -a v0.2.0 -m "v0.2.0 — first public release (crypto)"
git push origin v0.2.0
gh release create v0.2.0 --title "v0.2.0" --notes-file CHANGELOG.md
```

The git-install snippet in the README pins `revision: v0.2.0`, so the tag is what
consumers resolve.

---

## Step 4 — Subsequent releases

1. Copy the updated `dbt-package/` contents into the public repo working tree
   (or develop directly there).
2. Bump `version:` in `dbt_project.yml`, `hub_metadata.yml`, the README badge,
   and add a `CHANGELOG.md` entry — keep them in lockstep.
3. `make ci && make pre-publish-check`, commit, tag `vX.Y.Z`, push.

---

## Pre-publish anti-leak verification (`make pre-publish-check`)

Asserts, before any push:

- No `target/`, `dbt_packages/`, `logs/`, `.dbt/` at the package root.
- No `profiles.yml` (credentials) — only `profiles.yml.example` ships.
- No `.user.yml`.
- No nested `portfoliq/` dbt project (single root `dbt_project.yml` only).
- No package-licence MIT mention (must be ELv2). Upstream-provider MIT attributions
  (DeFiLlama, BigQuery public data) are allowed and unaffected.

---

## CI validation (no DB required)

The distributability gate is `make ci`, which runs from `integration_tests/` (a blank
consumer project): `dbt deps` (installs the pack via local path) + `dbt parse`. This is
exactly what a real consumer's `dbt deps` does, minus the network. A GitHub Actions
workflow can wrap the same two commands once the public repo exists.

---

## Pre-flight checklist (v0.2.0)

| # | Item | Status |
|---|------|--------|
| 1 | `LICENSE` present — **ELv2** (single licence, no MIT) | OK |
| 2 | `NOTICE.md` present (source obligations) | OK |
| 3 | `README.md` honest: crypto-only scope, git-install, consumer-pack model | OK |
| 4 | `dbt_project.yml` version `0.2.0`, profile `portfoliq`, require-dbt `>=1.7,<2` | OK |
| 5 | `hub_metadata.yml` — version `0.2.0`, license ELv2, adapters [postgres] | OK |
| 6 | 17 SQL models (3 dims + 10 facts + 4 sats) resolve via blank project | OK |
| 7 | 4 reference seeds (dim_chain, dim_event_type, dim_analysis_type, dim_tier) | OK |
| 8 | Schema tests in `models/schema.yml` + `seeds/schema.yml` + 3 singular tests | OK |
| 9 | `CONTRIBUTING.md` present | OK |
| 10 | `make ci` GREEN (deps + parse from blank consumer project) | OK |
| 11 | `make pre-publish-check` clean | OK |
| 12 | Single root dbt project (nested `portfoliq/` removed) | OK |
| 13 | No tracked `profiles.yml` / credentials | OK |
| ⚠ | **Public repo created + pushed + tagged v0.2.0** | **TODO — Wael** |

---

## Show HN post template (when public)

```
Title: Show HN: portfoliq-dbt — dbt package for a crypto Star Schema (ELv2)

A dbt consumer package that materializes a Kimball Star Schema (3 dims + 10 facts +
4 satellites) over crypto market data (CoinGecko, DeFiLlama, FRED, ECB, on-chain).
For data engineers building fintech apps who want analytics-ready models without
reinventing the wheel. You point a read-only dbt profile at our published star_public
schema and dbt build.

- GitHub: https://github.com/benamor001/portfoliq-dbt
- Docs: https://portfoliq.io/docs/bi-package
- 17 SQL models, 4 seeds, schema + singular tests, example queries
- Queryable in plain SQL → works with any PostgreSQL-compatible BI tool (ODBC/JDBC):
  Metabase, Tableau, Power BI, Lightdash, Superset. No bundled connector.
- License: Elastic License v2 (internal use free, SaaS resale restricted)

Not financial advice. Methodology disclosed.
```

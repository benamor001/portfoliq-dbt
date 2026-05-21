# Contributing to portfoliq-dbt

## Scope

This package ships transformation models only. No market data is included or accepted in contributions.

## Local validation (required before PR)

```bash
cd dbt-package
dbt deps
dbt parse --vars '{portfoliq_enable_star: false}'
dbt compile --vars '{portfoliq_enable_star: false}'
```

Against a live DB with `star_public` populated:

```bash
dbt run --vars '{portfoliq_enable_star: true}'
dbt test --vars '{portfoliq_enable_star: true}'
```

## PR conventions

- Branch name: `fix/<short-description>` or `feat/<short-description>`
- One logical change per PR.
- Every new model must have corresponding tests in `models/schema.yml` (unique, not_null at minimum).
- Do not touch `seeds/` CSV files without legal sign-off (data attribution clauses in `NOTICE.md`).

## Model conventions

- Staging layer: `stg_` prefix, reads from `raw.*` schema.
- Dimensions: `dim_` prefix, materialized as view by default.
- Facts: `fact_` prefix.
- Satellites: `sat_` prefix.
- Guard disabled state: all models must wrap their SELECT in `{{ config(...) }}` and respect `portfoliq_enable_star` var.

## Adding a new model

1. Create the SQL file under the appropriate folder (`models/dimensions/`, `models/facts/`, `models/satellites/`).
2. Add schema entry with column descriptions + tests in `models/schema.yml`.
3. Run compile + test locally.
4. Update `CHANGELOG.md` entry under `[Unreleased]`.

## Reporting issues

Open a GitHub Issue with:
- dbt version (`dbt --version`)
- Postgres version
- Minimal reproducible SQL or model name
- Observed vs. expected output

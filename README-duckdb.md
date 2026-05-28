# Run portfoliq dbt-package locally with DuckDB in 30s

No Postgres setup needed for local dev. DuckDB runs in-process — a single `.duckdb` file
is created at `/tmp/portfoliq_dev.duckdb`. No server, no credentials, no Docker.

## Prerequisites

- Python 3.11+
- pip

## Quick start

```bash
pip install dbt-duckdb==1.8.*
cp profiles.yml.example ~/.dbt/profiles.yml
dbt deps
dbt seed --target duckdb_dev --select tag:demo
dbt build --target duckdb_dev --select dim_asset fact_market_snapshot
```

What happens: the `tag:demo` seeds load 10 synthetic assets and 300 daily snapshot rows
into the local DuckDB file. `dbt build` then runs the models and their tests, validating
SQL compatibility across adapters without touching any real infrastructure.

> **Disclaimer:** Seed data is synthetic — not real market prices. Not financial advice.
> Methodology disclosed.

## Profile reference

The `duckdb_dev` target is defined in [`profiles.yml.example`](profiles.yml.example):

```yaml
duckdb_dev:
  type: duckdb
  path: /tmp/portfoliq_dev.duckdb
  schema: dv
  threads: 4
```

Copy `profiles.yml.example` to `~/.dbt/profiles.yml` (or merge the `duckdb_dev` block
into your existing profile). Do not commit `~/.dbt/profiles.yml`.

## Troubleshooting

**`ModuleNotFoundError: dbt.adapters.duckdb`**
Run `pip install dbt-duckdb==1.8.*`. The base `dbt-core` does not include DuckDB support.

**`Could not find profile named 'portfoliq'`**
Verify `~/.dbt/profiles.yml` contains the `portfoliq` key. Run `dbt debug --target duckdb_dev`
to inspect the resolved profile path.

**`OperationalError: database is locked`**
Another process holds the `.duckdb` file open. Close DuckDB Browser or kill the other
`dbt` process, then retry.

**`Compilation Error: relation "dim_asset" does not exist`**
Run `dbt seed --target duckdb_dev --select tag:demo` before `dbt build`. Seeds must be
loaded first to satisfy model dependencies.

**Models pass but tests fail on `relationships`**
Expected — the `relationships` tests on `demo_market_snapshots.asset_sk` require
`demo_assets` to be seeded first. Run seed with `--select tag:demo` (both seeds load
together). Do not seed them individually in separate runs.

## Postgres setup (production)

For the full Postgres connection (real data, all models), see the main
[README.md](README.md) and the `dev`/`prod` targets in `profiles.yml.example`.

# portfoliq-dbt

> portfolIQ Star Schema as a dbt package.
> Connect your dbt project to portfolIQ's financial data
> (crypto market, DeFi TVL, on-chain metrics, AI analysis)
> via a direct PostgreSQL read-only connection.
>
> **Not financial advice. Not a fatwa. Methodology disclosed.**
> See [portfoliq.io/methodology](https://portfoliq.io/methodology).

[![CI](https://github.com/portfoliq/portfoliq-dbt/actions/workflows/dbt-pack-ci.yml/badge.svg)](https://github.com/portfoliq/portfoliq-dbt/actions)
[![License: ELv2](https://img.shields.io/badge/License-ELv2-blue.svg)](LICENSE)
[![dbt](https://img.shields.io/badge/dbt-%3E%3D1.8-orange)](https://docs.getdbt.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org)

---

## What it is

Materialize the portfolIQ Star Schema (3 dimensions + 4 seeds + 10 facts + 4 satellites = 21 models) in your own dbt project via a read-only PostgreSQL connection.

Compatible with Power BI, Tableau, Metabase, Lightdash, and Cube.dev.

**Available on portfolIQ Growth plan and above.**

---

## Requirements

- `dbt-postgres >= 1.8`
- `dbt-utils >= 1.1.0` (installed automatically via `dbt deps`)
- portfolIQ Growth+ subscription
- SQL credentials provisioned via `POST /v1/billing/sql-credentials`
  ([docs](https://portfoliq.io/docs/get-started/sql-access))

---

## Quickstart (5 minutes)

### 1. Get SQL credentials

```bash
curl -X POST https://api.portfoliq.io/v1/billing/sql-credentials \
  -H "X-API-Key: YOUR_API_KEY"
```

Save the returned `username` and `password` — shown once only.

### 2. Install the package

Add to your `packages.yml`:

```yaml
packages:
  - git: "https://github.com/portfoliq/portfoliq-dbt.git"
    revision: main
    # or via dbt Hub once approved:
    # package: portfoliq/portfoliq_dbt
    # version: [">=0.1.0", "<1.0.0"]
```

Then run:

```bash
dbt deps
```

### 3. Configure your dbt profile

In `~/.dbt/profiles.yml`:

```yaml
portfoliq:
  target: dev
  outputs:
    dev:
      type: postgres
      host: db.portfoliq.io
      port: 5433
      user: "{{ env_var('PORTFOLIQ_SQL_USER') }}"
      password: "{{ env_var('PORTFOLIQ_SQL_PASSWORD') }}"
      dbname: portfoliq
      schema: star_public
      sslmode: require
      threads: 4
```

Export your credentials (never commit them):

```bash
export PORTFOLIQ_SQL_USER="piq_sql_xxxxxxxx"
export PORTFOLIQ_SQL_PASSWORD="your-password"
```

A full template with dev and prod targets is available in
[`profiles.yml.example`](profiles.yml.example).

### 4. Enable the Star Schema

In your client `dbt_project.yml`:

```yaml
vars:
  portfoliq_enable_star: true
```

### 5. Run and test

```bash
dbt run --select portfoliq.*
dbt test --select portfoliq.*
```

### 6. Query as usual

```sql
SELECT
  da.ticker,
  fms.price_consensus_usd,
  fms.market_cap_derived_usd,
  fms.snapshot_date
FROM star_public.fact_market_snapshot fms
JOIN star_public.dim_asset da
  ON fms.asset_sk = da.asset_sk
WHERE da.is_current = true
  AND fms.snapshot_date = CURRENT_DATE
ORDER BY fms.market_cap_derived_usd DESC NULLS LAST
LIMIT 10;
```

See [`examples/queries/`](examples/queries/) for 20 ready-to-use SQL queries.

---

## Available models

### Dimensions (3 views + 4 seeds)

| Model | Type | Grain | Description |
|---|---|---|---|
| `dim_asset` | SCD2 view | (asset_hk, valid_from) | Asset master — ticker, name, tier, contract address. Filter `is_current = true` for latest version. |
| `dim_news_source` | SCD1 view | news_source_id | Editorial news sources found in `sat_asset_news_public`. |
| `dim_date` | view | date | Calendar 2009-01-03 (Bitcoin genesis) to CURRENT_DATE + 1 year. |
| `dim_chain` | seed | chain_id | ~30 chains with EVM and L2 flags. |
| `dim_event_type` | seed | event_type_id | Crypto event type taxonomy. |
| `dim_analysis_type` | seed | analysis_type_id | AI analysis types with model and refresh cadence. |
| `dim_tier` | seed | tier | Market cap rank tier thresholds (Top 50 / 200 / 1000). |

### Facts (10 views / incremental)

| Model | Materialization | Grain | Description |
|---|---|---|---|
| `fact_market_snapshot` | view | (asset_sk, snapshot_date) | Daily price consensus (VWAP, 3+ exchanges), on-chain supply, derived market cap. |
| `fact_vwap_consensus` | view | (asset_sk, snapshot_ts, timeframe) | Sub-daily VWAP candles. `1h` for Tier 1 assets, `1d` for all. MAR-compliant. |
| `fact_onchain_core` | view | (asset_sk, snapshot_date) | Active addresses, tx count, fees — BTC and ETH in v1. |
| `fact_onchain_advanced` | view | (asset_sk, snapshot_date) | BTC only: Realized Cap, MVRV, NUPL, SOPR, HODL waves. Source: BigQuery public (MIT). |
| `fact_asset_fundamentals` | view | (asset_sk, snapshot_date) | P/S and P/R ratios for DeFi assets with a DeFiLlama link. |
| `fact_protocol_tvl` | view | (protocol_id, snapshot_date) | portfolIQ self-calculated TVL from on-chain pool balances. 1d/7d change. |
| `fact_protocol_economics` | view | (protocol_id, snapshot_date) | DeFi protocol fees and revenue — 24h, 7d, 30d. Source: DeFiLlama (MIT). |
| `fact_news_mention` | incremental | (article_hk, asset_sk) | News article x asset pairs — NER-extracted via Claude Haiku 4.5. |
| `fact_ai_analysis` | incremental | (asset_sk, analysis_type_id, generated_date) | AI-generated content per asset and analysis type. `ai_generated = true` always. |
| `fact_event` | incremental | (event_hk, asset_sk) | Crypto asset events — token launches, upgrades, exchange listings, etc. |

### Satellites (4 public_recomputed views)

| Model | Description |
|---|---|
| `sat_asset_metadata_public` | Multi-source asset metadata filtered for redistribution. `coingecko_id` excluded (ToS §6.2). |
| `sat_asset_news_public` | News articles: URL + editor + NER tokens + AI summary. Title/excerpt excluded (redistribution constraint). |
| `sat_asset_market_derived` | Derived market data: VWAP consensus price + market cap = VWAP x on-chain supply. |
| `sat_protocol_tvl_self` | TVL self-calculated from on-chain pool balances. DeFiLlama cross-check excluded (not redistributable). |

---

## Macros

| Macro | Description |
|---|---|
| `portfoliq_surrogate_key(cols)` | Wrapper around `dbt_utils.generate_surrogate_key` with column validation. |
| `safe_divide(numerator, denominator)` | Division returning NULL when denominator is zero. |
| `get_star_source_name(model)` | Resolves `star_public` schema name for dev/prod target switching. |
| `assert_star_enabled()` | Guard macro that raises a compile error when `portfoliq_enable_star = false`. |

---

## Feature flag

The package ships with a feature flag for dry-runs and conditional inclusion:

```yaml
vars:
  portfoliq_enable_star: false   # compiles but does not materialize any model
```

`dbt compile` will raise a clear error message. Set back to `true` to re-enable.
Useful to keep the package in your `packages.yml` without activating it.

---

## Tests

125 YAML tests pre-built (`unique`, `not_null`, `relationships`, `accepted_values`)
covering all 17 SQL models (3 dimensions + 10 facts + 4 satellites).

```bash
dbt test --select portfoliq.*
```

---

## Toggle Star Schema

To disable all package models without removing the package from `packages.yml`:

```yaml
# dbt_project.yml
vars:
  portfoliq_enable_star: false
```

---

## BI tool compatibility

| Tool | Connection type |
|---|---|
| Power BI Desktop | PostgreSQL connector (native) |
| Tableau | PostgreSQL connector (native) |
| Metabase | Add database → PostgreSQL |
| Lightdash | Native dbt project integration |
| Cube.dev | Native dbt project integration |

Full setup guides at:
- [portfoliq.io/docs/bi-package](https://portfoliq.io/docs/bi-package)
- [portfoliq.io/docs/bi-package/from-rest-to-bi](https://portfoliq.io/docs/bi-package/from-rest-to-bi)

---

## Examples

See [`examples/queries/`](examples/queries/) for 20 ready-to-use SQL queries:

- `01_top10_assets_by_market_cap.sql` — top 10 assets by derived market cap
- `02_btc_dominance_over_time.sql` — Bitcoin dominance last 90 days
- `05_ai_sentiment_trend.sql` — AI sentiment trend for a given asset
- `08_halal_assets_filter.sql` — halal-classified assets with market data
- `10_event_impact_on_price.sql` — crypto events vs price change 7 days after
- ... and 15 more

```bash
# Run a query directly in psql
psql "$DATABASE_URL" -f examples/queries/01_top10_assets_by_market_cap.sql
```

---

## Sources and attribution

This package reads from the following upstream data sources (transformation code
only — no data is bundled):

| Source | License | Usage |
|---|---|---|
| CoinGecko Demo API | CoinGecko ToS (free tier) | Token metadata — `coingecko_id` never re-exposed |
| DeFiLlama | MIT | Protocol TVL, fees, revenue |
| Federal Reserve (FRED) | Public domain | Macro indicators |
| ECB Statistical Data Warehouse | ECB open data terms | EUR rates, monetary data |
| BigQuery Public Datasets | CC0 / Apache 2.0 | On-chain reference data |

See [NOTICE.md](NOTICE.md) for full attribution obligations per source.

---

## License

Elastic License v2 (ELv2). See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

Key restriction: you may not provide this package to third parties as a hosted or
managed service where it provides access to a substantial set of the package's
features. Internal use and derived analytics are permitted.

---

## Roadmap

- HTTP API source mode (no SQL credentials required)
- Snowflake / BigQuery / DuckDB adapters
- Native Power BI `.pbix` templates
- Cube.dev semantic layer wrapper

---

## Need help?

- Docs: [portfoliq.io/docs/bi-package](https://portfoliq.io/docs/bi-package)
- SQL access guide: [portfoliq.io/docs/get-started/sql-access](https://portfoliq.io/docs/get-started/sql-access)
- API reference: [api.portfoliq.io/docs](https://api.portfoliq.io/docs)
- Status page: [status.portfoliq.io](https://status.portfoliq.io)
- GitHub Issues: [github.com/portfoliq/portfoliq-dbt/issues](https://github.com/portfoliq/portfoliq-dbt/issues)
- Email: hello@portfoliq.io

---

## Disclaimer

> Not financial advice. Not a fatwa. Methodology disclosed. Data provided for
> informational purposes only. AI-generated columns are tagged `ai_generated: true`
> and must be disclosed to end users. See [NOTICE.md](NOTICE.md) Clause E and F.

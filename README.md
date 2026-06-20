# portfoliq-dbt v0.2.0

> portfolIQ Star Schema as a dbt **consumer pack**.
> Connect your dbt project to portfolIQ's crypto financial data via a direct,
> read-only PostgreSQL connection to our published Star Schema (`star_public`).
>
> **This is a consumer pack, not a transformation framework.** It does not
> ingest or transform raw data on your side — it exposes portfolIQ's already-built
> Star Schema (dimensions, facts, satellites) as analytics-ready dbt models that
> read from the `star_public` schema we serve. You point a dbt profile at our
> read-only SQL endpoint and `dbt build` materialises thin pass-through views in
> your warehouse.
>
> **Scope today: crypto (top-1000 tier-ised).** Stocks / ETF / commodities / FX /
> macro are on the [Roadmap](#roadmap) — see the note there before relying on them.
>
> **Not financial advice. Not a fatwa. Methodology disclosed.**
> See [portfoliq.io/methodology](https://portfoliq.io/methodology).

[![API Status](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/portfoliq-io/portfolIQ/master/api/summary.json&label=API&style=flat)](https://status.portfoliq.io)
[![CI syntax](https://github.com/benamor001/portfoliq-dbt/actions/workflows/dbt-pack-ci.yml/badge.svg)](https://github.com/benamor001/portfoliq-dbt/actions/workflows/dbt-pack-ci.yml)
[![CI matrix Postgres+DuckDB](https://github.com/benamor001/portfoliq-dbt/actions/workflows/dbt-package.yml/badge.svg)](https://github.com/benamor001/portfoliq-dbt/actions/workflows/dbt-package.yml)
[![License: ELv2](https://img.shields.io/badge/License-ELv2-blue.svg)](LICENSE)
[![dbt](https://img.shields.io/badge/dbt-%3E%3D1.8-orange)](https://docs.getdbt.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org)
[![Version](https://img.shields.io/badge/version-0.2.0-green)](CHANGELOG.md)

---

## How this pack works (consumption model)

```
  portfolIQ (us)                          your warehouse
  ┌─────────────────────┐    read-only    ┌──────────────────────────┐
  │  star_public schema │ ◄────SQL──────  │  dbt build (this pack)   │
  │  (we build & serve) │                 │  → thin pass-through      │
  │  dims / facts / sats │                 │    views + reference seeds│
  └─────────────────────┘                 └──────────────────────────┘
                                                     │
                                                     ▼
                                            your BI / SQL / models
```

You do **not** ingest or transform raw market data. You connect a dbt profile to our
read-only `star_public` endpoint, run `dbt deps && dbt seed && dbt build`, and the pack
materialises analytics-ready views (plus 4 reference seeds) in your warehouse. It is a
**consumer pack**, not an ELT framework. Use the resulting Star Schema from SQL or any
PostgreSQL-compatible BI tool.

---

## DuckDB support — local dev without Postgres

Run the full package locally in 30 seconds using DuckDB. No server, no credentials.

See **[README-duckdb.md](README-duckdb.md)** for the 5-command quick start.

---

## TL;DR

```yaml
# packages.yml
packages:
  - git: "https://github.com/benamor001/portfoliq-dbt.git"
    revision: v0.2.0
```

```bash
dbt deps && dbt seed && dbt build
```

> **Scope note (v0.2.0):** this pack ships **crypto** models only. The multi-asset
> `enable_stocks / enable_etf / enable_commodities / enable_macro / enable_fx`
> toggles are **roadmap** — they are not wired in this release and have no effect
> if set. See [Roadmap](#roadmap).

---

## Installation

### 1. Get SQL credentials

```bash
curl -X POST https://api.portfoliq.io/v1/billing/sql-credentials \
  -H "X-API-Key: YOUR_API_KEY"
```

Save the returned `username` and `password` — shown once only.
Requires a portfolIQ Growth plan or above.

### 2. Add to packages.yml

```yaml
packages:
  - git: "https://github.com/benamor001/portfoliq-dbt.git"
    revision: v0.2.0
```

Then run `dbt deps`.

> **Distribution channel:** git-install is the **primary** method. The package is
> ELv2-licensed (not an OSI-approved licence), so a dbt Hub listing is not guaranteed —
> always rely on the git URL above. Pin to a tag (`v0.2.0`), not a branch.

### 3. Configure your dbt profile

```yaml
# ~/.dbt/profiles.yml
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

```bash
export PORTFOLIQ_SQL_USER="piq_sql_xxxxxxxx"
export PORTFOLIQ_SQL_PASSWORD="your-password"
```

See [`profiles.yml.example`](profiles.yml.example) for dev/prod template.

---

## Quick Start (crypto — no config needed)

```bash
dbt deps
dbt seed
dbt build --select portfoliq.*
```

This builds the crypto dimensions, facts and satellites as views over `star_public`,
plus the reference seeds. No other configuration is required.

```sql
-- Crypto top 10 by market cap
SELECT da.ticker, fms.price_consensus_usd, fms.market_cap_derived_usd, fms.snapshot_date
FROM star_public.fact_market_snapshot fms
JOIN star_public.dim_asset da ON fms.asset_sk = da.asset_sk
WHERE da.is_current = true AND fms.snapshot_date = CURRENT_DATE
ORDER BY fms.market_cap_derived_usd DESC NULLS LAST LIMIT 10;
```

---

## Multi-asset — roadmap (NOT in v0.2.0)

Stocks, ETF, commodities, FX and macro coverage is planned but **not shipped in this
release**. The `enable_stocks / enable_etf / enable_commodities / enable_macro /
enable_fx` toggles described in earlier drafts are **not wired** in v0.2.0 and have no
effect. Crypto data quality is production-grade; the other asset classes are still
thin upstream (see [Roadmap](#roadmap)). This section will be filled in when the
multi-asset models land.

---

## Models reference

### Dimensions

| Model | Type | Grain | Exposure | Notes |
|---|---|---|---|---|
| `dim_asset` | SCD2 view | (asset_hk, valid_from) | public | reads `star_public` |
| `dim_date` | view | date | public | reads `star_public` |
| `dim_news_source` | SCD1 view | news_source_id | public | reads `star_public` |
| `dim_chain` | seed | chain_id | reference | bundled CSV |
| `dim_event_type` | seed | event_type_id | reference | bundled CSV |
| `dim_analysis_type` | seed | analysis_type_id | reference | bundled CSV |
| `dim_tier` | seed | tier | reference | bundled CSV |

### Facts

All facts in v0.2.0 are **crypto** and read from `star_public`.

| Model | Materialization | Grain | Exposure |
|---|---|---|---|
| `fact_market_snapshot` | view | (asset_sk, snapshot_date) | public |
| `fact_vwap_consensus` | view | (asset_sk, snapshot_ts, timeframe) | public |
| `fact_onchain_core` | view | (asset_sk, snapshot_date) | public |
| `fact_onchain_advanced` | view | (asset_sk, snapshot_date) | public |
| `fact_asset_fundamentals` | view | (asset_sk, snapshot_date) | public |
| `fact_protocol_tvl` | view | (protocol_id, snapshot_date) | public |
| `fact_protocol_economics` | view | (protocol_id, snapshot_date) | public |
| `fact_news_mention` | view | (article_hk, asset_sk) | public |
| `fact_ai_analysis` | view | (asset_sk, analysis_type_id, generated_date) | public |
| `fact_event` | view | (event_hk, asset_sk) | public |

> `fact_market_price`, `fact_stock_fundamentals`, `fact_etf_holdings`,
> `fact_macro_observation`, `fact_market_correlation` are **roadmap** — not in v0.2.0.

### Satellites (public_recomputed)

| Model | Description | Exposure |
|---|---|---|
| `sat_asset_metadata_public` | Multi-source metadata filtered for redistribution | public_recomputed |
| `sat_asset_news_public` | News articles: URL + editor + NER + AI summary | public_recomputed |
| `sat_asset_market_derived` | VWAP consensus price + derived market cap | public_recomputed |
| `sat_protocol_tvl_self` | Self-calculated TVL from on-chain balances | public_recomputed |

---

## Schema output — key columns

### `fact_market_snapshot` (crypto daily snapshot)

| Column | Type | Description |
|---|---|---|
| `asset_sk` | text | FK → `dim_asset.asset_sk` |
| `asset_id` | integer | Stable public BK |
| `snapshot_date` | date | Date for `dim_date` join |
| `price_consensus_usd` | numeric | VWAP multi-exchange consensus price |
| `market_cap_derived_usd` | numeric | Derived market cap (redistributable) |
| `supply_on_chain` | numeric | On-chain circulating supply |
| `exchanges_count` | smallint | Number of venues in the consensus |
| `methodology_version` | text | Audit trail |

The full column contract for every model lives in [`models/schema.yml`](models/schema.yml),
which is also rendered by `dbt docs generate`.

---

## Running tests

```bash
# All package tests
dbt test --select portfoliq.*

# Tests for a specific model
dbt test --select fact_market_snapshot
```

The package ships schema tests (not_null, unique, accepted_values, relationships,
dbt_utils range/expression checks) declared in `models/schema.yml` and `seeds/schema.yml`,
plus 3 singular tests in `tests/`. Default severity is configured per the host project;
override with `tests: portfoliq: +severity: error` to enforce in your CI.

---

## BI tool compatibility (SQL-direct, no native connector)

This package builds a **Kimball-style Star Schema queryable in plain SQL**. There is
**no bundled BI connector** — you consume the views/tables directly over PostgreSQL.
Any BI tool that speaks PostgreSQL (ODBC/JDBC) works: point it at the schema where the
package materialised, and model the joins on the conformed `asset_sk` / `date_key` keys.

| Tool | How it consumes the pack |
|---|---|
| **Metabase / Lightdash / Superset** | Direct PostgreSQL connection to the materialised schema |
| **Tableau / Power BI** | PostgreSQL ODBC/JDBC driver, DirectQuery against the Star Schema |
| **Cube / dbt Semantic Layer** | Build your own semantic model on top of these dbt models |

A first-class Power BI template and a Cube wrapper are on the [Roadmap](#roadmap).

---

## SQL examples

See [`queries/cross-asset/`](queries/cross-asset/) for ready-to-use queries.

> **Scope note:** some example queries (cross-asset correlations, stock leverage inputs,
> macro regimes, polymorphic `fact_market_price`) target **roadmap** models/data that
> are not part of the v0.2.0 crypto pack. They are shipped as reference patterns; the
> crypto-only examples (e.g. top-50 market snapshots) run today.
>
> **Compliance note (D-166 / AMF-001):** portfolIQ never exposes a halal/Sharia
> compliance **verdict**, an `is_halal_*` boolean, or a per-standard pass/fail. The
> screening queries below expose **raw inputs only** (leverage ratios, market data);
> any verdict is computed downstream by the consumer (e.g. HalalStack).

| File | Description |
|---|---|
| `01_btc_sp500_correlation_252d.sql` | BTC vs SPY rolling 252d Pearson correlation |
| `02_gold_btc_correlation_regimes.sql` | Gold vs BTC by FEDFUNDS rate regime |
| `03_top10_crypto_stock_correlation_matrix.sql` | Top 10 crypto × top 10 stocks matrix |
| `06_halal_screening_aaoifi_crypto_top50.sql` | Top 50 crypto by market cap (no verdict) |
| `07_halal_screening_djim_inputs_stocks.sql` | US stocks leverage ratio input (raw, no verdict) |
| `09_multi_standard_comparison.sql` | Screening leverage inputs (raw, no verdict) |
| `10_fact_market_price_all_kinds.sql` | Polymorphic price: all 5 asset kinds |
| `13_macro_regime_classification.sql` | FRED macro regime: expansion/overheating |
| `19_cross_asset_portfolio_dashboard.sql` | Full portfolio dashboard (5 assets, 4 facts) |
| `20_dbt_hub_asset_lineage.sql` | Data lineage audit — MAR/BMR traceability |

---

## Data sources and licenses

This package contains transformation code only. No data is bundled. The `License`
column below describes the **upstream data provider's** licence (for attribution),
not this package's licence — the package itself is ELv2 (see [License](#license)).

Sources powering the **v0.2.0 crypto** models:

| Source | Upstream license | Redistribution | Usage in models |
|---|---|---|---|
| CoinGecko Demo API | CoinGecko ToS | Derived metrics only | Crypto metadata, OHLCV raw |
| DeFiLlama | MIT (upstream) | Yes | Protocol TVL, fees |
| FRED (Federal Reserve) | Public domain (US Gov) | Yes | Macro indicators (regimes) |
| ECB Statistical Data Warehouse | ECB open data | Yes | EUR rates |

Sources for **roadmap** (stocks / ETF) models — listed for transparency, not yet shipped:

| Source | Upstream license | Redistribution | Roadmap usage |
|---|---|---|---|
| SEC EDGAR | Public domain (17 CFR §200.80) | Yes | Stock fundamentals (XBRL), 13F |
| KIDs PRIIPs (EU UCITS) | EU public (UCITS IV Dir.) | Yes | ETF holdings EU |
| Tiingo / Polygon / FMP | Internal use only | Derived OK, raw forbidden | Stock OHLCV → derived only |
| EDINET (Japan FSA) | PDL 1.0 + attribution | Commercial OK | Japan stock filings |
| TWSE Taiwan | Open Government License v1.0 | Yes | Taiwan exchange data |

See [NOTICE.md](NOTICE.md) for full obligations per source.

---

## License

Elastic License v2 (ELv2). See [LICENSE](LICENSE).

Key restriction: you may not provide this package to third parties as a hosted or
managed service where it provides access to a substantial set of the package features.
Internal use and derived analytics are permitted.

---

## Disclaimer

> Not financial advice. Not a fatwa. Methodology disclosed. Data provided for
> informational purposes only. AI-generated columns are tagged `ai_generated: true`
> and must be disclosed to end users. See [NOTICE.md](NOTICE.md) Clause E and F.
>
> Halal classification is based on portfolIQ's disclosed methodology only.
> Consult a qualified Islamic finance scholar for formal religious rulings.

---

## Roadmap

- **Multi-asset models** — stocks, ETF, commodities, FX, macro (the `enable_*` toggles
  and `fact_market_price` polymorphic fact). Crypto-quality first; other classes are
  still thin upstream.
- HTTP API source mode (no SQL credentials required)
- Snowflake / BigQuery adapters (DuckDB already supported for local dev)
- Native Power BI `.pbix` templates
- Cube.dev semantic layer wrapper
- dbt Hub submission (subject to ELv2 / non-OSI acceptance; git-install is the
  primary distribution channel)

---

## Need help?

- Docs: [portfoliq.io/docs/bi-package](https://portfoliq.io/docs/bi-package)
- SQL access: [portfoliq.io/docs/get-started/sql-access](https://portfoliq.io/docs/get-started/sql-access)
- API reference: [api.portfoliq.io/docs](https://api.portfoliq.io/docs)
- Status: [status.portfoliq.io](https://status.portfoliq.io)
- GitHub Issues: [github.com/benamor001/portfoliq-dbt/issues](https://github.com/benamor001/portfoliq-dbt/issues)
- Email: hello@portfoliq.io

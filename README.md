# portfoliq-dbt v0.2.0

> portfolIQ Star Schema as a dbt package — now multi-asset.
> Connect your dbt project to portfolIQ's financial data (crypto, stocks, ETF, commodities, FX, macro)
> via a direct PostgreSQL read-only connection.
>
> **Not financial advice. Not a fatwa. Methodology disclosed.**
> See [portfoliq.io/methodology](https://portfoliq.io/methodology).

[![CI](https://github.com/portfoliq/portfoliq-dbt/actions/workflows/dbt-pack-ci.yml/badge.svg)](https://github.com/portfoliq/portfoliq-dbt/actions)
[![License: ELv2](https://img.shields.io/badge/License-ELv2-blue.svg)](LICENSE)
[![dbt](https://img.shields.io/badge/dbt-%3E%3D1.8-orange)](https://docs.getdbt.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org)
[![Version](https://img.shields.io/badge/version-0.2.0-green)](CHANGELOG.md)

---

## TL;DR

```yaml
# packages.yml
packages:
  - git: "https://github.com/portfoliq/portfoliq-dbt.git"
    revision: v0.2.0

# dbt_project.yml — enable what you need (all false by default)
vars:
  enable_stocks:      true   # SEC EDGAR fundamentals + derived OHLCV
  enable_etf:         true   # 13F/N-PORT + KIDs PRIIPs EU
  enable_commodities: true   # FRED spot prices (WTI, Gold, Silver…)
  enable_macro:       true   # FRED + ECB SDW economic series
  enable_fx:          true   # ECB SDW EUR pairs + derived cross-rates
```

```bash
dbt deps && dbt seed && dbt build
```

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
  - git: "https://github.com/portfoliq/portfoliq-dbt.git"
    revision: v0.2.0
    # Or via dbt Hub once approved:
    # package: portfoliq/portfoliq_dbt
    # version: [">=0.2.0", "<1.0.0"]
```

Then run `dbt deps`.

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

## Quick Start (crypto-only — default, no config needed)

v0.2.0 is **backwards-compatible**. If you were using v0.1.x, no change is needed to get
the same crypto-only behavior:

```bash
dbt deps
dbt seed
dbt build --select portfoliq.*
```

All v0.1.0 models run identically. No new tables are created unless you opt in (see below).

```sql
-- Crypto top 10 by market cap (identical to v0.1)
SELECT da.ticker, fms.price_consensus_usd, fms.market_cap_derived_usd, fms.snapshot_date
FROM star_public.fact_market_snapshot fms
JOIN star_public.dim_asset da ON fms.asset_sk = da.asset_sk
WHERE da.is_current = true AND fms.snapshot_date = CURRENT_DATE
ORDER BY fms.market_cap_derived_usd DESC NULLS LAST LIMIT 10;
```

---

## Multi-asset opt-in

Set any combination in your `dbt_project.yml`. All vars default to `false`.

```yaml
vars:
  enable_stocks:      true   # Activates: stg_sec_edgar_xbrl, sat_stock_fundamentals,
                             #            sat_stock_market_derived, fact_stock_fundamentals,
                             #            fact_market_price (stock slice)
  enable_etf:         true   # Activates: stg_sec_edgar_13f, stg_kid_priips, sat_etf_holdings,
                             #            sat_etf_nav, link_etf_constituent, fact_etf_holdings,
                             #            fact_market_price (etf slice)
  enable_commodities: true   # Activates: sat_commodity_spot, fact_market_price (commodity slice)
  enable_macro:       true   # Activates: stg_fred_observations, stg_ecb_sdw_observations,
                             #            sat_macro_observation, fact_macro_observation
  enable_fx:          true   # Activates: stg_ecb_sdw_observations (fx subset), sat_fx_rate,
                             #            fact_market_price (fx slice)
```

**Important:** `fact_market_price` (polymorphic) is always compiled, but only returns rows for
enabled kinds. With all vars `false` (default), it returns crypto data only
(via `sat_asset_vwap_consensus`).

---

## Models reference

### Dimensions

| Model | Type | Grain | Exposure | Depends on var |
|---|---|---|---|---|
| `dim_asset` | SCD2 view | (asset_hk, valid_from) | public | — (stable) |
| `dim_date` | view | date | public | — |
| `dim_news_source` | SCD1 view | news_source_id | public | — |
| `dim_asset_kind` | seed | asset_kind_key | public | — (always loaded) |
| `dim_chain` | seed | chain_id | public | — |
| `dim_event_type` | seed | event_type_id | public | — |
| `dim_analysis_type` | seed | analysis_type_id | public | — |
| `dim_tier` | seed | tier | public | — |

### Facts

| Model | Materialization | Grain | Exposure | Depends on var |
|---|---|---|---|---|
| `fact_market_snapshot` | view | (asset_sk, snapshot_date) | public | — (stable v0.1) |
| `fact_vwap_consensus` | view | (asset_sk, snapshot_ts, timeframe) | public | — (stable v0.1) |
| `fact_onchain_core` | view | (asset_sk, snapshot_date) | public | — (stable v0.1) |
| `fact_onchain_advanced` | view | (asset_sk, snapshot_date) | public | — (stable v0.1) |
| `fact_asset_fundamentals` | view | (asset_sk, snapshot_date) | public | — (stable v0.1) |
| `fact_protocol_tvl` | view | (protocol_id, snapshot_date) | public | — (stable v0.1) |
| `fact_protocol_economics` | view | (protocol_id, snapshot_date) | public | — (stable v0.1) |
| `fact_news_mention` | incremental | (article_hk, asset_sk) | public | — (stable v0.1) |
| `fact_ai_analysis` | incremental | (asset_sk, analysis_type_id, generated_date) | public | — (stable v0.1) |
| `fact_event` | incremental | (event_hk, asset_sk) | public | — (stable v0.1) |
| `fact_market_price` | view | (asset_sk, ts, timeframe) | public_recomputed | — (always, but gated slices) **new v0.2** |
| `fact_stock_fundamentals` | view | (asset_sk, period_end_date, filing_type) | public | enable_stocks **new v0.2** |
| `fact_etf_holdings` | view | (etf_asset_sk, constituent_identifier, snapshot_month) | public | enable_etf **new v0.2** |
| `fact_macro_observation` | view | (series_sk, observation_date, vintage_date) | public | enable_macro **new v0.2** |
| `fact_market_correlation` | incremental | (asset_sk_a, asset_sk_b, window_days, snapshot_date) | public_recomputed | — (always active) **new v0.2** |

### Satellites (public_recomputed)

| Model | Description | Exposure |
|---|---|---|
| `sat_asset_metadata_public` | Multi-source metadata filtered for redistribution | public_recomputed |
| `sat_asset_news_public` | News articles: URL + editor + NER + AI summary | public_recomputed |
| `sat_asset_market_derived` | VWAP consensus price + derived market cap | public_recomputed |
| `sat_protocol_tvl_self` | Self-calculated TVL from on-chain balances | public_recomputed |
| `sat_asset_classification` | Sector, GICS, halal attributes — all asset kinds | public_recomputed **new v0.2** |
| `sat_stock_market_derived` | Stock VWAP-derived OHLCV (redistribuable derivé) | public_recomputed **new v0.2** |

---

## Schema output — key columns

### `fact_market_price` (polymorphic)

| Column | Type | Description |
|---|---|---|
| `asset_sk` | text | FK → `dim_asset.asset_sk` |
| `asset_id` | integer | Stable public BK |
| `asset_kind` | text | crypto/stock/etf/commodity/fx |
| `listing_venue` | text | MIC or authority (coingecko, XNAS, XNYS…) |
| `ts` | timestamptz | Timestamp timezone-aware |
| `snapshot_date` | date | Date for `dim_date` join |
| `timeframe` | text | '1h' (crypto Tier 1) or '1d' (all) |
| `open` | numeric(28,10) | NULL for crypto/etf/commodity/fx |
| `high` | numeric(28,10) | NULL for crypto/etf/commodity/fx |
| `low` | numeric(28,10) | NULL for crypto/etf/commodity/fx |
| `close` | numeric(28,10) | NEVER NULL — the price contract |
| `volume` | numeric(28,2) | Shares for stock; NULL for others |
| `venues_count` | smallint | Crypto VWAP consensus only |
| `methodology_version` | text | Audit trail |

### `dim_asset` (v0.2 additions — additive strict)

New columns added: `asset_kind` (text, NOT NULL), `listing_venue` (text, NOT NULL),
`asset_kind_label` (text, NOT NULL, denormalized from `dim_asset_kind`).
All v0.1 columns unchanged.

---

## Breaking-safe upgrade v0.1.x → v0.2.0

**TL;DR: No breaking change. Default behaviour after upgrade: identical to v0.1.x.**

### Step 1 — pin the new version

```yaml
# packages.yml
packages:
  - git: "https://github.com/portfoliq/portfoliq-dbt.git"
    revision: v0.2.0
```

### Step 2 — run dbt deps + dbt seed

```bash
dbt deps
dbt seed --select dim_asset_kind  # new seed, 6 fixed rows, idempotent
```

### Step 3 — run dbt build (identical to v0.1)

```bash
dbt build
```

Zero new tables or views are created. The DAG is identical to v0.1.x.
All `enable_*` vars default to `false`, so no new models are compiled.

### Step 4 — opt-in to multi-asset (when ready)

```yaml
# dbt_project.yml
vars:
  enable_stocks:      true
  enable_etf:         true
  enable_commodities: true
  enable_macro:       true
  enable_fx:          true
```

Then re-run: `dbt build`

This builds the new staging/satellite/fact models for enabled kinds.

### Schema drift on `dim_asset`

Three columns are added to `dim_asset` in v0.2: `asset_kind`, `listing_venue`, `asset_kind_label`.

If you have downstream models or BI dashboards that do `SELECT * FROM dim_asset` into a
fixed-schema sink, refactor to explicit column lists OR drop+recreate the sink table.

`SELECT col1, col2 FROM dim_asset` remains fully valid. No action needed.

### Rolling back

Pin back to v0.1.x in `packages.yml`, then:

```bash
dbt clean && dbt deps && dbt build
```

The opt-in vars gracefully resolve to `false` if absent.

---

## Running tests

```bash
# All tests (v0.1 + v0.2)
dbt test --select portfoliq.*

# Only v0.1 tests (regression gate)
dbt test --select tag:v0.1

# Only v0.2 tests
dbt test --select tag:v0.2

# Specific model
dbt test --select fact_market_price
```

125 YAML tests for v0.1 models. 13 additional tests for v0.2 (range, relationships,
symmetry, ETF weight sum, vintage anti-lookahead).

---

## Connectors BI compatibility

| Tool | Compatibility | Remarks |
|---|---|---|
| **Metabase** | Auto FK detection on `asset_sk` | `asset_kind_label` in dimension filters |
| **Tableau** | TIL relationship model | Conformed dim Kimball-compatible |
| **Power BI** | Star schema model, DirectQuery | PG latency <200ms P95 |
| **Lightdash** | Reads dbt yml `meta.*` | `exposure: public_recomputed` respected |
| **Cube** | Schema YAML generation | Full semantic layer |

Full setup guides: [portfoliq.io/docs/bi-package](https://portfoliq.io/docs/bi-package)

---

## SQL examples

See [`queries/cross-asset/`](queries/cross-asset/) for 20 ready-to-use queries:

| File | Description |
|---|---|
| `01_btc_sp500_correlation_252d.sql` | BTC vs SPY rolling 252d Pearson correlation |
| `02_gold_btc_correlation_regimes.sql` | Gold vs BTC by FEDFUNDS rate regime |
| `03_top10_crypto_stock_correlation_matrix.sql` | Top 10 crypto × top 10 stocks matrix |
| `06_halal_screening_aaoifi_crypto_top50.sql` | Top 50 crypto AAOIFI screening |
| `07_halal_screening_djim_inputs_stocks.sql` | US stocks DJIM ratio inputs |
| `09_multi_standard_comparison.sql` | AAOIFI vs DJIM vs Wahed comparison |
| `10_fact_market_price_all_kinds.sql` | Polymorphic price: all 5 asset kinds |
| `13_macro_regime_classification.sql` | FRED macro regime: expansion/overheating |
| `19_cross_asset_portfolio_dashboard.sql` | Full portfolio dashboard (5 assets, 4 facts) |
| `20_dbt_hub_asset_lineage.sql` | Data lineage audit — MAR/BMR traceability |

---

## Data sources and licenses

This package contains transformation code only. No data is bundled.

| Source | License | Redistribution | Usage in models |
|---|---|---|---|
| CoinGecko Demo API | CoinGecko ToS | Derived metrics only | Crypto metadata, OHLCV raw |
| DeFiLlama | MIT | Yes | Protocol TVL, fees |
| FRED (Federal Reserve) | Public domain (US Gov) | Yes | Macro indicators, commodity spots |
| ECB Statistical Data Warehouse | ECB open data | Yes | EUR rates, monetary data |
| SEC EDGAR | Public domain (17 CFR §200.80) | Yes | Stock fundamentals (XBRL), 13F |
| KIDs PRIIPs (EU UCITS) | EU public (UCITS IV Dir.) | Yes | ETF holdings EU |
| Tiingo / Polygon / FMP | Internal use only | Derived OK, raw forbidden | `sat_stock_ohlcv` (internal_only) → `sat_stock_market_derived` (redistribuable) |
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

- HTTP API source mode (no SQL credentials required)
- Snowflake / BigQuery / DuckDB adapters
- Native Power BI `.pbix` templates — multi-asset
- Cube.dev semantic layer wrapper with `dim_asset_kind` filters
- dbt Hub submission (M9+)

---

## Need help?

- Docs: [portfoliq.io/docs/bi-package](https://portfoliq.io/docs/bi-package)
- SQL access: [portfoliq.io/docs/get-started/sql-access](https://portfoliq.io/docs/get-started/sql-access)
- API reference: [api.portfoliq.io/docs](https://api.portfoliq.io/docs)
- Status: [status.portfoliq.io](https://status.portfoliq.io)
- GitHub Issues: [github.com/portfoliq/portfoliq-dbt/issues](https://github.com/portfoliq/portfoliq-dbt/issues)
- Email: hello@portfoliq.io

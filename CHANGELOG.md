# Changelog

All notable changes to portfoliq-dbt are documented in this file.

Format: [Semantic Versioning](https://semver.org/). Unreleased changes are staged in `main`.

> **Scope correction (2026-06-08).** The "Multi-asset opt-in" entries documented under
> 0.2.0 below (the `enable_*` vars; `dim_asset_kind` seed; `fact_market_price`,
> `fact_stock_fundamentals`, `fact_etf_holdings`, `fact_macro_observation`,
> `fact_market_correlation`; and the stock/ETF/macro satellites) describe **planned work
> that did NOT ship** in the released package. The actual **shipped v0.2.0 is crypto-only**
> (10 crypto facts, 3 dimension views, 4 reference seeds, 4 satellites — all reading
> `star_public`). Those multi-asset entries are retained as **roadmap** history; treat the
> "What actually shipped in v0.2.0" section as authoritative.

---

## [0.2.1] — 2026-07-06

### Fixed

- Seed column type `double` → `double precision` (`double` is not a valid Postgres type —
  `dbt seed` failed on vanilla Postgres/TimescaleDB installs).
- CI matrix harness for the pack (structure/compilation validated on fresh DB).

### Changed — compliance scrub (D-166 / AMF-001)

- **No compliance verdict is ever exposed by this package.** The cross-asset and
  example screening queries (`06`, `07`, `08`, `09`, `19`) were rewritten to remove
  all `is_halal_aaoifi` / `sharia_purification_ratio` / `aaoifi_verdict` columns and
  every per-standard pass/fail (`*_screen_pass`, `preliminary_halal_pass`,
  `standards_agreement`). They now expose **raw screening inputs only** (leverage
  ratios, market data). Applying any threshold and reaching a verdict is the
  consumer's responsibility (e.g. HalalStack, the screening sovereign).
  Those `is_halal_*` columns also never existed in the shipped `dim_asset` view, so
  the previous queries were both a legal exposure and broken drift.
- `hub_metadata.yml` keyword `halal-screening` → `screening-inputs`.

---

## What actually shipped in v0.2.0 (authoritative)

- **Dimensions (views):** `dim_asset` (SCD2), `dim_date`, `dim_news_source`.
- **Reference seeds (CSV):** `dim_chain`, `dim_event_type`, `dim_analysis_type`, `dim_tier`
  (+ `demo_assets`, `demo_market_snapshots` synthetic seeds for DuckDB local dev).
- **Facts (crypto, over `star_public`):** `fact_market_snapshot`, `fact_vwap_consensus`,
  `fact_onchain_core`, `fact_onchain_advanced`, `fact_asset_fundamentals`,
  `fact_protocol_tvl`, `fact_protocol_economics`, `fact_news_mention`,
  `fact_ai_analysis`, `fact_event`.
- **Satellites:** `sat_asset_metadata_public`, `sat_asset_news_public`,
  `sat_asset_market_derived`, `sat_protocol_tvl_self`.
- **Licence:** Elastic License v2 (ELv2). **Distribution:** git-install.

---

## [0.2.0] — 2026-05-22 (planned scope — see correction above)

### Added

**Multi-asset opt-in system**
- `dim_asset_kind` — conformed seed dimension, 6 values: `crypto`, `stock`, `etf`, `commodity`, `fx`, `macro`. Includes `sort_order` and `listing_authority` for BI display and lineage audit.
- 5 opt-in vars in `dbt_project.yml`: `enable_stocks`, `enable_etf`, `enable_commodities`, `enable_macro`, `enable_fx` (all `false` by default — zero impact on v0.1.x users who upgrade without touching vars).

**New fact models**
- `fact_market_price` — polymorphic price fact, grain `(asset_sk, ts, timeframe)`. Consolidates OHLCV across all enabled asset kinds via conditional UNION ALL. `close` is NEVER NULL. Always compiled; returns crypto data when all enable_* vars are false.
- `fact_stock_fundamentals` — SEC EDGAR XBRL fundamentals: EPS, revenue, net income, EBITDA, debt, shares, accession_number. Gated `enable_stocks`. Grain: `(asset_sk, period_end_date, filing_type)`.
- `fact_etf_holdings` — 13F/N-PORT US + KIDs PRIIPs EU holdings: constituent weights, market values, shares held. Gated `enable_etf`. Grain: `(etf_asset_sk, constituent_identifier, snapshot_month)`.
- `fact_macro_observation` — FRED + ECB SDW economic series with vintage anti-lookahead preservation. Gated `enable_macro`. Grain: `(series_sk, observation_date, vintage_date)`.
- `fact_market_correlation` — cross-asset rolling Pearson correlation (30d/90d/252d windows). Always active (no var gate). Grain: `(asset_sk_a, asset_sk_b, window_days, snapshot_date)`.

**New satellite models**
- `sat_asset_classification` — unified classification Sat (GICS sector, halal attributes) for all asset kinds. Always active.
- `sat_macro_observation` — raw macro time-series from FRED + ECB SDW. Gated `enable_macro`.
- `sat_stock_fundamentals` — XBRL parsed annual/quarterly fundamentals. Gated `enable_stocks`. Exposure: `public`.
- `sat_stock_ohlcv` — raw Tiingo/AV OHLCV. Gated `enable_stocks`. Exposure: `internal_only` (redistribution forbidden).
- `sat_stock_market_derived` — VWAP-derived OHLCV from `sat_stock_ohlcv` (redistribuable derivé). Gated `enable_stocks`. Exposure: `public_recomputed`.
- `sat_etf_holdings` — holdings from 13F/N-PORT + KIDs PRIIPs. Gated `enable_etf`.
- `sat_etf_nav` — ETF NAV end-of-day. Gated `enable_etf`.
- `sat_commodity_contract_spec` — commodity instrument specs (FRED series metadata). Gated `enable_commodities`.
- `sat_commodity_spot` — FRED commodity spot prices. Gated `enable_commodities`.
- `sat_fx_rate` — ECB SDW FX rates (EUR pairs + derived cross-rates). Gated `enable_fx`.

**New staging models**
- `stg_fred_observations` — FRED API observations (commodities + macro subsets). Gated by combination of `enable_commodities` and `enable_macro`.
- `stg_sec_edgar_xbrl` — SEC EDGAR XBRL parsed GAAP data. Gated `enable_stocks`.
- `stg_sec_edgar_13f` — SEC 13F institutional holdings. Gated `enable_etf`.
- `stg_ecb_sdw_observations` — ECB SDW API observations (macro + FX subsets). Gated by `enable_macro OR enable_fx`.
- `stg_tiingo_stock_eod` — Tiingo end-of-day stock prices. Gated `enable_stocks`. Internal use only.
- `stg_kid_priips` — EU UCITS KIDs PRIIPs holdings (EU ETF constituents). Gated `enable_etf`.

**New link model**
- `link_etf_constituent` — links ETF to its constituents in the Data Vault layer. Gated `enable_etf`.

**Documentation and tooling**
- 13 new dbt tests (range, Pearson symmetry, ETF weight sum 95-105%, vintage anti-lookahead, SEC accession_number unique, hub_asset hash collision check, relationships across all new facts).
- 20 SQL example queries in `queries/cross-asset/` covering correlations, raw screening inputs (leverage ratios — no verdict, see D-166 scrub above), polymorphic pricing, macro regimes, ETF concentration (HHI), and data lineage audit.
- CI smoke script `scripts/ci_dbt_smoke.sh` — idempotent end-to-end test: parse → compile → seed → run v0.1 → test v0.1 → run v0.2 → test v0.2.
- GitHub Actions workflow `.github/workflows/dbt-smoke.yml` — runs on push to `main` (paths: `dbt/**`) and `workflow_dispatch`.
- Release workflow `.github/workflows/dbt-release.yml` — smoke gate → subtree push → tag.
- `NOTICE.md` v0.2.0 section — legal status of 7 new sources (FRED, ECB, SEC EDGAR, Tiingo internal_only, KIDs PRIIPs, EDINET, TWSE).

### Modified

- `dim_asset` — additive extension: 3 new columns `asset_kind` (text NOT NULL), `listing_venue` (text NOT NULL), `asset_kind_label` (text NOT NULL, denormalized from `dim_asset_kind`). All v0.1 columns unchanged. `SELECT v0.1` queries remain valid.
- `hub_asset` — Business Key extended to composite `(symbol, kind, listing_venue)` to support multi-asset disambiguation.
- `dbt_project.yml` — 5 new opt-in vars added (all `false` by default).

### Fixed

- Schema drift documentation: README now warns against `SELECT *` into fixed-schema sinks downstream of `dim_asset`. Explicit column lists recommended.

---

## [0.1.0] — 2026-01-15 (Sprint 17-21)

Initial release — crypto-only pack.

- 3 dimensions: `dim_asset` (SCD2), `dim_date`, `dim_news_source`
- 4 seeds: `dim_chain`, `dim_event_type`, `dim_analysis_type`, `dim_tier`
- 10 fact models: `fact_market_snapshot`, `fact_vwap_consensus`, `fact_onchain_core`, `fact_onchain_advanced`, `fact_asset_fundamentals`, `fact_protocol_tvl`, `fact_protocol_economics`, `fact_news_mention`, `fact_ai_analysis`, `fact_event`
- 4 public_recomputed satellites: `sat_asset_metadata_public`, `sat_asset_news_public`, `sat_asset_market_derived`, `sat_protocol_tvl_self`
- 4 macros: `portfoliq_surrogate_key`, `safe_divide`, `get_star_source_name`, `assert_star_enabled`
- 125 dbt tests
- ELv2 license, NOTICE.md, CONTRIBUTING.md, PUBLISHING.md

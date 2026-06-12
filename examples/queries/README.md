# portfolIQ dbt pack — Example Queries

20 ready-to-run SQL queries demonstrating the `star_public` schema.
Copy and paste into your BI tool, psql, or notebook.

All queries target `star_public.*` tables directly (no `{{ ref() }}` — these are
standalone examples for end users, not dbt models).

> Not financial advice. Not a fatwa. Methodology disclosed at portfoliq.io/methodology.

---

## Query Index

| # | File | Title | BI Tool |
|---|------|-------|---------|
| 01 | `01_top10_assets_by_market_cap.sql` | Top 10 Assets by Market Cap (Latest Snapshot) | Any |
| 02 | `02_btc_dominance_over_time.sql` | Bitcoin Dominance Over Time (Last 90 Days) | Power BI, Tableau |
| 03 | `03_ps_ratio_leaders.sql` | P/S Ratio Leaders — Potentially Undervalued DeFi Assets | Tableau, Metabase |
| 04 | `04_tvl_top_protocols.sql` | Top 10 DeFi Protocols by TVL (Latest Snapshot) | Metabase, Tableau |
| 05 | `05_ai_sentiment_trend.sql` | AI Sentiment Trend for a Given Asset (Last 30 Days) | Power BI |
| 06 | `06_onchain_nvt_ratio.sql` | Bitcoin NVT Ratio (Last 90 Days) — On-Chain Valuation Proxy | Any |
| 07 | `07_vwap_vs_market_price.sql` | VWAP Consensus vs Spot Price Divergence (Last 7 Days) | Tableau, Power BI |
| 08 | `08_halal_assets_filter.sql` | Halal-Classified Assets with Market Data (Latest Snapshot) | Any |
| 09 | `09_tier1_assets_daily.sql` | Tier 1 Assets Daily Snapshot (Last 30 Days) | Power BI |
| 10 | `10_event_impact_on_price.sql` | Crypto Events and Price Change in the Following 7 Days | Tableau |
| 11 | `11_news_mention_frequency.sql` | News Mention Frequency by Source for a Given Asset (Last 30 Days) | Metabase, Lightdash |
| 12 | `12_protocol_fee_revenue_30d.sql` | Protocol Fee and Revenue Leaders — 30-Day Cumulative | Tableau, Power BI |
| 13 | `13_eth_active_addresses.sql` | Ethereum Active Addresses (Last 90 Days) — Adoption Proxy | Power BI, Metabase |
| 14 | `14_stablecoin_dominance.sql` | Stablecoin Dominance in Total Market Cap (Last 90 Days) | Any |
| 15 | `15_asset_metadata_freshness.sql` | Asset Metadata Freshness — Data Age per Active Asset | Metabase |
| 16 | `16_ai_analysis_cost_monitoring.sql` | AI Analysis Production Monitoring (Last 30 Days) | Metabase |
| 17 | `17_dim_date_calendar_joins.sql` | Calendar-Enriched Price Data — dim_date Join Example | Power BI |
| 18 | `18_cross_chain_tvl.sql` | Cross-Chain TVL Breakdown (Latest Snapshot) | Tableau, Power BI |
| 19 | `19_exchange_volume_breakdown.sql` | Exchange Volume Breakdown via VWAP Consensus (Last 7 Days) | Power BI, Tableau |
| 20 | `20_fundamentals_yoy_growth.sql` | Protocol Revenue YoY Growth (Year-over-Year) | Any |

---

## Prerequisites

- PostgreSQL 14+ with the `star_public` schema loaded (portfolIQ server or local dev mirror).
- The `portfoliq_reference` schema (dbt seeds) for chain and event type metadata.
- Read access granted to the `star_public` schema.

## Usage

```bash
# Run a query directly in psql
psql "$DATABASE_URL" -f examples/queries/01_top10_assets_by_market_cap.sql

# Or copy-paste into Metabase / Tableau / Power BI Data Source
```

## Customising Queries

Most queries are parameterised by ticker (e.g. `da.ticker = 'BTC'`).
Replace with any ticker available in `star_public.dim_asset`.

Date ranges use `CURRENT_DATE - INTERVAL '...'` — no hardcoded dates.

## Legal

- Data sourced from portfolIQ pipelines. Derived data is redistributable.
- CoinGecko nominal prices are **never** exposed (ToS §6.2 compliance).
- Not financial advice. Not a fatwa. Not a sharia ruling.
- Methodology: portfoliq.io/methodology

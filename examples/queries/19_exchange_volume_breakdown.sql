-- ============================================================
-- portfolIQ dbt pack — Example Query 19
-- Title: Exchange Volume Breakdown via VWAP Consensus (Last 7 Days)
-- Business context: Analyse VWAP consensus data over the past 7 days
--   for a given asset. The fact_vwap_consensus table provides derived
--   VWAP and exchange count — individual exchange weights are not exposed
--   (portfolIQ does not redistribute per-exchange raw data per legal constraints).
--   Use this to detect consensus quality shifts (exchanges_count drop,
--   max_source_weight_pct spike) as market microstructure signals.
-- Suggested BI tool: Power BI (table + conditional formatting), Tableau
-- Tables: star_public.fact_vwap_consensus, star_public.dim_asset
-- Filters: asset ticker = 'BTC' + date range last 7 days + timeframe = '1h'
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

-- Replace 'BTC' with any Tier 1 ticker. Use timeframe = '1d' for all tiers.
SELECT
    fvc.snapshot_ts,
    fvc.snapshot_date,
    da.name                     AS asset_name,
    da.ticker                   AS asset_ticker,
    fvc.timeframe,
    fvc.vwap_usd                AS vwap_consensus_usd,
    fvc.exchanges_count,
    fvc.max_source_weight_pct   AS max_exchange_weight_pct,
    fvc.methodology_version
FROM star_public.fact_vwap_consensus  fvc
JOIN star_public.dim_asset            da
    ON  da.asset_sk   = fvc.asset_sk
    AND da.is_current = TRUE
    AND da.ticker     = 'BTC'
WHERE
    fvc.snapshot_date >= CURRENT_DATE - INTERVAL '7 days'
    AND fvc.timeframe  = '1h'  -- use '1d' for non-Tier-1 assets
ORDER BY fvc.snapshot_ts ASC;

-- NOTE: Individual exchange names and weights are not exposed in the Star Schema.
-- portfolIQ aggregates them into exchanges_count and max_source_weight_pct
-- to comply with CoinGecko ToS §6.2 and MAR anti-manipulation rules.

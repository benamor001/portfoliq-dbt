-- ============================================================
-- portfolIQ dbt pack — Example Query 09
-- Title: Tier 1 Assets Daily Snapshot (Last 30 Days)
-- Business context: Pull the daily market snapshot for all Tier 1
--   (top 50 by market cap) crypto assets over the last 30 days.
--   Perfect for time-series visualisations, matrix tables, or building
--   a benchmarking dataset for quant backtests.
-- Suggested BI tool: Power BI (matrix table / heatmap)
-- Tables: star_public.fact_market_snapshot, star_public.dim_asset
-- Filters: tier = 1 + snapshot_date range last 30 days
-- Not financial advice. Methodology disclosed.
-- ============================================================

SELECT
    fms.snapshot_date,
    da.name                     AS asset_name,
    da.ticker                   AS asset_ticker,
    da.tier,
    fms.price_consensus_usd     AS price_usd,
    fms.market_cap_derived_usd  AS market_cap_usd,
    fms.supply_on_chain,
    fms.exchanges_count,
    fms.methodology_version
FROM star_public.fact_market_snapshot  fms
JOIN star_public.dim_asset             da
    ON  da.asset_sk   = fms.asset_sk
    AND da.is_current = TRUE
    AND da.tier       = 1
WHERE
    fms.snapshot_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY
    fms.snapshot_date DESC,
    fms.market_cap_derived_usd DESC NULLS LAST;

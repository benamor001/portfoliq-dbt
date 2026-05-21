-- ============================================================
-- portfolIQ dbt pack — Example Query 01
-- Title: Top 10 Assets by Market Cap (Latest Snapshot)
-- Business context: Identify the largest crypto assets by derived market
--   capitalization at yesterday's snapshot. Ideal for leaderboard widgets
--   and portfolio benchmarking dashboards.
-- Suggested BI tool: Any (table / bar chart)
-- Tables: star_public.fact_market_snapshot, star_public.dim_asset
-- Filters: snapshot_date = CURRENT_DATE - 1 day (no full scan)
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

SELECT
    da.name                     AS asset_name,
    da.ticker                   AS asset_ticker,
    da.tier                     AS tier,
    fms.price_consensus_usd     AS price_usd,
    fms.market_cap_derived_usd  AS market_cap_usd,
    fms.exchanges_count         AS exchanges_contributing,
    fms.methodology_version
FROM star_public.fact_market_snapshot  fms
JOIN star_public.dim_asset             da
    ON  da.asset_sk    = fms.asset_sk
    AND da.is_current  = TRUE
WHERE
    fms.snapshot_date = CURRENT_DATE - INTERVAL '1 day'
    AND fms.market_cap_derived_usd IS NOT NULL
ORDER BY fms.market_cap_derived_usd DESC
LIMIT 10;

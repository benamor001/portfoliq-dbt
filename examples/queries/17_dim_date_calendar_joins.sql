-- ============================================================
-- portfolIQ dbt pack — Example Query 17
-- Title: Calendar-Enriched Price Data — dim_date Join Example
-- Business context: Demonstrates how to enrich market data with calendar
--   attributes from dim_date (is_weekend, quarter, US market holidays).
--   Essential for time-series analytics in BI tools that lack built-in
--   date intelligence. Shows weekly patterns (BTC tends to be less liquid
--   on weekends) and quarterly seasonality.
-- Suggested BI tool: Power BI (time intelligence / calendar slicers)
-- Tables: star_public.fact_market_snapshot, star_public.dim_date,
--         star_public.dim_asset
-- Filters: asset ticker = 'BTC' + date range last 30 days
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

-- Replace 'BTC' with any ticker available in dim_asset.
SELECT
    dd.date                     AS date_day,
    dd.year,
    dd.quarter,
    dd.month,
    dd.month_name               AS month_name,
    dd.week_of_year,
    dd.day_of_week,
    dd.day_name                 AS day_name,
    dd.is_weekend,
    dd.is_us_market_holiday,
    da.name                     AS asset_name,
    da.ticker                   AS asset_ticker,
    fms.price_consensus_usd     AS price_usd,
    fms.market_cap_derived_usd  AS market_cap_usd,
    fms.exchanges_count
FROM star_public.fact_market_snapshot  fms
JOIN star_public.dim_date              dd
    ON  dd.date_key  = fms.date_key
JOIN star_public.dim_asset             da
    ON  da.asset_sk  = fms.asset_sk
    AND da.is_current = TRUE
    AND da.ticker     = 'BTC'
WHERE
    fms.snapshot_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY dd.date ASC;

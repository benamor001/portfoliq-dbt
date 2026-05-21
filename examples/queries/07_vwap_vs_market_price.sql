-- ============================================================
-- portfolIQ dbt pack — Example Query 07
-- Title: VWAP Consensus vs Spot Price Divergence (Last 7 Days)
-- Business context: Detects price dislocation between the multi-exchange
--   VWAP consensus (redistribution-safe derived data) and the daily
--   market snapshot price. A significant divergence can indicate exchange
--   manipulation, liquidity fragmentation, or data lag. Useful for
--   data quality monitoring and quant signal research.
-- Suggested BI tool: Tableau (dual-axis line chart), Power BI
-- Tables: star_public.fact_vwap_consensus, star_public.fact_market_snapshot,
--         star_public.dim_asset
-- Filters: asset ticker = 'BTC' + date range last 7 days + timeframe = '1d'
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

-- Replace 'BTC' with any Tier 1 ticker available in fact_vwap_consensus.
SELECT
    fvc.snapshot_date,
    da.name                     AS asset_name,
    da.ticker                   AS asset_ticker,
    fvc.vwap_usd                AS vwap_consensus_usd,
    fvc.exchanges_count         AS exchanges_in_consensus,
    fvc.max_source_weight_pct,
    fms.price_consensus_usd     AS market_snapshot_price_usd,
    ROUND(
        100.0 * (fms.price_consensus_usd - fvc.vwap_usd)
        / NULLIF(fvc.vwap_usd, 0),
        4
    )                           AS price_divergence_pct
FROM star_public.fact_vwap_consensus    fvc
JOIN star_public.dim_asset              da
    ON  da.asset_sk   = fvc.asset_sk
    AND da.is_current = TRUE
    AND da.ticker     = 'BTC'
LEFT JOIN star_public.fact_market_snapshot  fms
    ON  fms.asset_sk      = fvc.asset_sk
    AND fms.snapshot_date = fvc.snapshot_date
WHERE
    fvc.snapshot_date >= CURRENT_DATE - INTERVAL '7 days'
    AND fvc.timeframe  = '1d'
ORDER BY fvc.snapshot_date ASC;

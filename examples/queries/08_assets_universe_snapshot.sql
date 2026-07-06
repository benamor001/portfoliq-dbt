-- ============================================================
-- portfolIQ dbt pack — Example Query 08
-- Title: Top Assets by Market Cap with Latest Snapshot (Tier-filtered)
-- Business context: List the portfolIQ asset universe enriched with yesterday's
--   consensus market data. Useful as a base table for screening dashboards;
--   any compliance filter is applied downstream by the consumer.
--
-- D-166 / AMF-001 — IMPORTANT (this is a PUBLIC package):
--   portfolIQ does NOT serve a religious- or ethics-compliance VERDICT, nor an
--   compliance boolean. The screening verdict is sovereign to downstream
--   consumers (screening stays consumer-side). This example exposes market data only.
--   Not financial advice. Methodology disclosed.
--
-- Suggested BI tool: Any (filtered table, card KPIs)
-- Tables: star_public.dim_asset, star_public.fact_market_snapshot
-- Filters: snapshot_date = yesterday + is_current = true
-- ============================================================

SELECT
    da.name                     AS asset_name,
    da.ticker                   AS asset_ticker,
    da.tier                     AS tier,
    da.contract_address,
    fms.price_consensus_usd     AS price_usd,
    fms.market_cap_derived_usd  AS market_cap_usd,
    fms.exchanges_count         AS exchanges_contributing,
    da.methodology_version      AS methodology_version
FROM star_public.dim_asset              da
LEFT JOIN star_public.fact_market_snapshot  fms
    ON  fms.asset_sk      = da.asset_sk
    AND fms.snapshot_date = CURRENT_DATE - INTERVAL '1 day'
WHERE
    da.is_current = TRUE
ORDER BY fms.market_cap_derived_usd DESC NULLS LAST;

-- ============================================================
-- portfolIQ dbt pack — Example Query 13
-- Title: Ethereum Active Addresses (Last 90 Days) — Adoption Proxy
-- Business context: Active address count is a key on-chain adoption
--   metric. Sustained growth in active ETH addresses signals real
--   network usage beyond speculation. BTC and ETH are the only assets
--   covered by fact_onchain_core in portfolIQ v1.
--   Factual on-chain aggregates. Not financial advice.
-- Suggested BI tool: Power BI (area chart), Metabase
-- Tables: star_public.fact_onchain_core, star_public.dim_asset
-- Filters: asset ticker = 'ETH' + date range last 90 days
-- Not financial advice. Methodology disclosed.
-- ============================================================

SELECT
    foc.snapshot_date,
    da.name                 AS asset_name,
    da.ticker               AS asset_ticker,
    foc.active_addresses,
    foc.tx_count            AS transaction_count,
    foc.fees_total_usd      AS fees_usd,
    foc.avg_fee_usd,
    foc.source_rpc
FROM star_public.fact_onchain_core  foc
JOIN star_public.dim_asset          da
    ON  da.asset_sk   = foc.asset_sk
    AND da.is_current = TRUE
    AND da.ticker     = 'ETH'
WHERE
    foc.snapshot_date >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY foc.snapshot_date ASC;

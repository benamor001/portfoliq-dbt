-- ============================================================
-- portfolIQ dbt pack — Example Query 06
-- Title: Bitcoin NVT Ratio (Last 90 Days) — On-Chain Valuation Proxy
-- Business context: The Network Value to Transactions (NVT) ratio is
--   computed as market_cap / daily on-chain transaction volume (USD).
--   A high NVT suggests the network is overvalued relative to its
--   economic throughput (similar to P/E for equities). BTC-only in v1.
--   Factual descriptive metric. Not financial advice.
-- Suggested BI tool: Any (line chart)
-- Tables: star_public.fact_onchain_advanced, star_public.fact_market_snapshot,
--         star_public.dim_asset
-- Filters: asset ticker = 'BTC' + date range last 90 days
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

SELECT
    foa.snapshot_date,
    foa.realized_cap_usd,
    foa.mvrv_ratio,
    foa.nupl,
    foa.sopr,
    foa.realized_price_usd,
    foa.circulating_supply_btc,
    -- NVT proxy: market_cap / on-chain tx count (volume USD not available — use tx_count as proxy)
    -- TODO: replace foc.tx_count with daily_volume_usd when available in fact_onchain_core
    ROUND(
        fms.market_cap_derived_usd::numeric / NULLIF(foc.tx_count, 0),
        4
    )                           AS nvt_ratio_proxy,
    fms.market_cap_derived_usd  AS market_cap_usd
FROM star_public.fact_onchain_advanced  foa
JOIN star_public.dim_asset              da
    ON  da.asset_sk   = foa.asset_sk
    AND da.is_current = TRUE
    AND da.ticker     = 'BTC'
LEFT JOIN star_public.fact_market_snapshot  fms
    ON  fms.asset_sk      = foa.asset_sk
    AND fms.snapshot_date = foa.snapshot_date
LEFT JOIN star_public.fact_onchain_core     foc
    ON  foc.asset_sk      = foa.asset_sk
    AND foc.snapshot_date = foa.snapshot_date
WHERE
    foa.snapshot_date >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY foa.snapshot_date ASC;

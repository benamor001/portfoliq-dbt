-- ============================================================
-- portfolIQ dbt pack — Example Query 14
-- Title: Stablecoin Dominance in Total Market Cap (Last 90 Days)
-- Business context: Track the share of the total crypto market cap
--   held by major stablecoins (USDT, USDC, DAI). A rising stablecoin
--   dominance indicates risk-off sentiment — capital parking in USD-pegged
--   assets while waiting to re-deploy. Classic macro signal.
-- Suggested BI tool: Any (line chart, stacked area)
-- Tables: star_public.fact_market_snapshot, star_public.dim_asset
-- Filters: snapshot_date range last 90 days (prevents full scan)
-- Not financial advice. Methodology disclosed.
-- ============================================================

WITH daily_market AS (
    SELECT
        fms.snapshot_date,
        SUM(fms.market_cap_derived_usd)
            FILTER (WHERE da.ticker IN ('USDT', 'USDC', 'DAI'))
                                            AS stablecoin_market_cap_usd,
        SUM(fms.market_cap_derived_usd)     AS total_market_cap_usd
    FROM star_public.fact_market_snapshot  fms
    JOIN star_public.dim_asset             da
        ON  da.asset_sk   = fms.asset_sk
        AND da.is_current = TRUE
    WHERE
        fms.snapshot_date          >= CURRENT_DATE - INTERVAL '90 days'
        AND fms.market_cap_derived_usd IS NOT NULL
    GROUP BY fms.snapshot_date
)
SELECT
    snapshot_date,
    stablecoin_market_cap_usd,
    total_market_cap_usd,
    ROUND(
        100.0 * stablecoin_market_cap_usd / NULLIF(total_market_cap_usd, 0),
        2
    )   AS stablecoin_dominance_pct
FROM daily_market
ORDER BY snapshot_date ASC;

-- NOTE: Tickers 'USDT', 'USDC', 'DAI' must be present in dim_asset.
-- Expand the IN list with additional stablecoins (BUSD, TUSD, FRAX) as needed.

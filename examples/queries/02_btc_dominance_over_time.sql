-- ============================================================
-- portfolIQ dbt pack — Example Query 02
-- Title: Bitcoin Dominance Over Time (Last 90 Days)
-- Business context: Track Bitcoin's share of total crypto market
--   capitalisation day by day. A classic macro signal: rising BTC
--   dominance often indicates altcoin weakness (risk-off rotation).
-- Suggested BI tool: Power BI (line chart), Tableau
-- Tables: star_public.fact_market_snapshot, star_public.dim_asset
-- Filters: snapshot_date range last 90 days (prevents full scan)
-- Not financial advice. Methodology disclosed.
-- ============================================================

WITH daily_totals AS (
    SELECT
        fms.snapshot_date,
        SUM(fms.market_cap_derived_usd)
            FILTER (WHERE da.ticker = 'BTC')    AS btc_market_cap_usd,
        SUM(fms.market_cap_derived_usd)         AS total_market_cap_usd
    FROM star_public.fact_market_snapshot  fms
    JOIN star_public.dim_asset             da
        ON  da.asset_sk   = fms.asset_sk
        AND da.is_current = TRUE
    WHERE
        fms.snapshot_date >= CURRENT_DATE - INTERVAL '90 days'
        AND fms.market_cap_derived_usd IS NOT NULL
    GROUP BY fms.snapshot_date
)
SELECT
    snapshot_date,
    btc_market_cap_usd,
    total_market_cap_usd,
    ROUND(
        100.0 * btc_market_cap_usd / NULLIF(total_market_cap_usd, 0),
        2
    ) AS btc_dominance_pct
FROM daily_totals
ORDER BY snapshot_date;

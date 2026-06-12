-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 04: WTI + Gold vs AAPL + MSFT — 30d Rolling Correlation
-- Requires: enable_commodities = true, enable_stocks = true
-- Source tables: marts.fact_market_correlation, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

WITH assets AS (
    -- Collect all 4 asset surrogate keys
    SELECT asset_sk, ticker, asset_kind
    FROM marts.dim_asset
    WHERE ticker IN ('WTI', 'XAUUSD', 'AAPL', 'MSFT')
      AND is_current = true
),
wti   AS (SELECT asset_sk FROM assets WHERE ticker = 'WTI'),
gold  AS (SELECT asset_sk FROM assets WHERE ticker = 'XAUUSD'),
aapl  AS (SELECT asset_sk FROM assets WHERE ticker = 'AAPL'),
msft  AS (SELECT asset_sk FROM assets WHERE ticker = 'MSFT'),
pairs AS (
    -- 4 cross-pairs: WTI×AAPL, WTI×MSFT, GOLD×AAPL, GOLD×MSFT
    SELECT 'WTI'    AS commodity, 'AAPL'  AS equity,
           LEAST(wti.asset_sk, aapl.asset_sk) AS sk_a,
           GREATEST(wti.asset_sk, aapl.asset_sk) AS sk_b
    FROM wti CROSS JOIN aapl
    UNION ALL
    SELECT 'WTI', 'MSFT',
           LEAST(wti.asset_sk, msft.asset_sk), GREATEST(wti.asset_sk, msft.asset_sk)
    FROM wti CROSS JOIN msft
    UNION ALL
    SELECT 'GOLD', 'AAPL',
           LEAST(gold.asset_sk, aapl.asset_sk), GREATEST(gold.asset_sk, aapl.asset_sk)
    FROM gold CROSS JOIN aapl
    UNION ALL
    SELECT 'GOLD', 'MSFT',
           LEAST(gold.asset_sk, msft.asset_sk), GREATEST(gold.asset_sk, msft.asset_sk)
    FROM gold CROSS JOIN msft
)
SELECT
    p.commodity,
    p.equity,
    fmc.snapshot_date,
    ROUND(fmc.pearson_30d::numeric, 4)   AS pearson_30d,
    ROUND(fmc.pearson_90d::numeric, 4)   AS pearson_90d,
    fmc.obs_count_30d                    AS sample_size_30d
FROM pairs p
JOIN marts.fact_market_correlation fmc
    ON fmc.asset_sk_a = p.sk_a
   AND fmc.asset_sk_b = p.sk_b
WHERE fmc.snapshot_date >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY fmc.snapshot_date DESC, p.commodity, p.equity;

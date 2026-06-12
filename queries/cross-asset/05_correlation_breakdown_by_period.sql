-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 05: BTC vs AAPL — 30d/90d/252d Correlation Side-by-Side
-- Requires: enable_stocks = true
-- Source tables: marts.fact_market_correlation, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

WITH btc  AS (SELECT asset_sk FROM marts.dim_asset WHERE ticker = 'BTC'  AND is_current = true AND asset_kind = 'crypto' LIMIT 1),
     aapl AS (SELECT asset_sk FROM marts.dim_asset WHERE ticker = 'AAPL' AND is_current = true AND asset_kind = 'stock'  LIMIT 1)
SELECT
    fmc.snapshot_date,
    -- All three window sizes side by side for direct comparison
    ROUND(fmc.pearson_30d::numeric,  4)   AS pearson_30d,
    ROUND(fmc.pearson_90d::numeric,  4)   AS pearson_90d,
    ROUND(fmc.pearson_252d::numeric, 4)   AS pearson_252d,
    fmc.obs_count_30d                     AS n_30d,
    fmc.obs_count_90d                     AS n_90d,
    fmc.obs_count_252d                    AS n_252d,
    -- Convergence flag: short-term correlation trending toward long-term
    CASE
        WHEN ABS(fmc.pearson_30d - fmc.pearson_252d) < 0.10
             THEN 'converging'
        WHEN fmc.pearson_30d > fmc.pearson_252d + 0.20
             THEN 'short_spike_high'
        WHEN fmc.pearson_30d < fmc.pearson_252d - 0.20
             THEN 'short_spike_low'
        ELSE 'normal_spread'
    END                                   AS term_structure
FROM marts.fact_market_correlation fmc
CROSS JOIN btc
CROSS JOIN aapl
WHERE (fmc.asset_sk_a = LEAST(btc.asset_sk, aapl.asset_sk)
   AND fmc.asset_sk_b = GREATEST(btc.asset_sk, aapl.asset_sk))
  AND fmc.snapshot_date >= CURRENT_DATE - INTERVAL '2 years'
ORDER BY fmc.snapshot_date DESC;

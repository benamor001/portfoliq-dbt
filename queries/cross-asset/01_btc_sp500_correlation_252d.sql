-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 01: BTC vs SPY (S&P 500 ETF) Rolling 252d Correlation
-- Requires: enable_etf = true
-- Source tables: marts.fact_market_correlation, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

WITH btc AS (
    -- Retrieve BTC asset surrogate key
    SELECT asset_sk, asset_id, ticker, name
    FROM marts.dim_asset
    WHERE ticker = 'BTC'
      AND is_current = true
      AND asset_kind = 'crypto'
    LIMIT 1
),
spy AS (
    -- Retrieve SPY ETF asset surrogate key
    SELECT asset_sk, asset_id, ticker, name
    FROM marts.dim_asset
    WHERE ticker = 'SPY'
      AND is_current = true
      AND asset_kind = 'etf'
    LIMIT 1
),
correlation AS (
    -- Pull 252-day rolling Pearson correlation from fact_market_correlation
    -- fact_market_correlation stores asset_sk_a < asset_sk_b (canonical order)
    SELECT
        fmc.snapshot_date,
        fmc.pearson_252d                     AS correlation_252d,
        fmc.pearson_90d                      AS correlation_90d,
        fmc.pearson_30d                      AS correlation_30d,
        fmc.obs_count_252d                   AS sample_size_252d
    FROM marts.fact_market_correlation fmc
    CROSS JOIN btc
    CROSS JOIN spy
    WHERE (fmc.asset_sk_a = btc.asset_sk AND fmc.asset_sk_b = spy.asset_sk)
       OR (fmc.asset_sk_a = spy.asset_sk AND fmc.asset_sk_b = btc.asset_sk)
      AND fmc.window_days = 252
    ORDER BY fmc.snapshot_date DESC
)
SELECT
    snapshot_date,
    ROUND(correlation_252d::numeric, 4)  AS pearson_252d,
    ROUND(correlation_90d::numeric, 4)   AS pearson_90d,
    ROUND(correlation_30d::numeric, 4)   AS pearson_30d,
    sample_size_252d,
    -- Regime classification: high/medium/low/inverse correlation
    CASE
        WHEN correlation_252d > 0.7  THEN 'high_positive'
        WHEN correlation_252d > 0.3  THEN 'moderate_positive'
        WHEN correlation_252d > -0.3 THEN 'low'
        WHEN correlation_252d > -0.7 THEN 'moderate_negative'
        ELSE 'high_negative'
    END                                  AS correlation_regime
FROM correlation
ORDER BY snapshot_date DESC
LIMIT 365;  -- Last 365 snapshot dates (roughly 1 year of daily results)

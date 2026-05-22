-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 02: Gold vs BTC Correlation by Macro Regime
-- Requires: enable_commodities = true, enable_macro = true
-- Source tables: marts.fact_market_correlation, marts.fact_macro_observation,
--               marts.dim_asset, marts.dim_date
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

WITH gold AS (
    -- XAUUSD (Gold spot) as commodity
    SELECT asset_sk FROM marts.dim_asset
    WHERE ticker = 'XAUUSD' AND asset_kind = 'commodity' AND is_current = true LIMIT 1
),
btc AS (
    SELECT asset_sk FROM marts.dim_asset
    WHERE ticker = 'BTC' AND asset_kind = 'crypto' AND is_current = true LIMIT 1
),
fedfunds_series AS (
    -- FRED FEDFUNDS series — effective federal funds rate
    SELECT asset_sk FROM marts.dim_asset
    WHERE ticker = 'FEDFUNDS' AND asset_kind = 'macro' AND is_current = true LIMIT 1
),
fed_regime AS (
    -- Classify macro regime by FEDFUNDS level
    SELECT
        fo.observation_date,
        fo.value                                      AS fedfunds_rate,
        CASE
            WHEN fo.value < 1.0  THEN 'ultra_low'     -- ZIRP / near-ZIRP
            WHEN fo.value < 2.0  THEN 'low'
            WHEN fo.value < 4.0  THEN 'moderate'
            WHEN fo.value >= 4.0 THEN 'high'
        END                                           AS rate_regime
    FROM marts.fact_macro_observation fo
    CROSS JOIN fedfunds_series fs
    WHERE fo.series_sk = fs.asset_sk
      AND fo.vintage_date = fo.observation_date  -- use real-time vintage only
),
correlation AS (
    -- Rolling 90d Pearson correlation Gold vs BTC
    SELECT
        fmc.snapshot_date,
        fmc.pearson_90d    AS gold_btc_corr_90d,
        fmc.pearson_252d   AS gold_btc_corr_252d
    FROM marts.fact_market_correlation fmc
    CROSS JOIN gold g
    CROSS JOIN btc b
    WHERE (fmc.asset_sk_a = g.asset_sk AND fmc.asset_sk_b = b.asset_sk)
       OR (fmc.asset_sk_a = b.asset_sk AND fmc.asset_sk_b = g.asset_sk)
)
SELECT
    c.snapshot_date,
    ROUND(c.gold_btc_corr_90d::numeric, 4)   AS gold_btc_corr_90d,
    ROUND(c.gold_btc_corr_252d::numeric, 4)  AS gold_btc_corr_252d,
    fr.fedfunds_rate,
    fr.rate_regime,
    -- Safe haven convergence: both assets moving together during stress
    CASE
        WHEN c.gold_btc_corr_90d > 0.5 AND fr.rate_regime = 'high'
             THEN 'flight_to_safety_convergence'
        WHEN c.gold_btc_corr_90d < -0.3
             THEN 'divergent_safe_haven'
        ELSE 'neutral'
    END                                       AS regime_interpretation
FROM correlation c
JOIN fed_regime fr ON fr.observation_date = c.snapshot_date
ORDER BY c.snapshot_date DESC;

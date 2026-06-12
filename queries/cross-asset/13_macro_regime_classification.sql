-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 13: Macro Regime Classification (FRED Data)
--   Expansion / Contraction / Overheating based on FEDFUNDS + CPIAUCSL + UNRATE
-- Requires: enable_macro = true
-- Source tables: marts.fact_macro_observation, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

WITH macro_series AS (
    -- Resolve series asset_sks
    SELECT asset_sk, ticker FROM marts.dim_asset
    WHERE ticker IN ('FEDFUNDS', 'CPIAUCSL', 'UNRATE', 'GDP')
      AND asset_kind = 'macro'
      AND is_current = true
),
fedfunds AS (
    -- Federal Funds Rate (monthly)
    SELECT fo.observation_date, fo.value AS fedfunds_rate
    FROM marts.fact_macro_observation fo
    JOIN macro_series ms ON ms.asset_sk = fo.series_sk AND ms.ticker = 'FEDFUNDS'
    -- Use latest vintage only (no look-ahead bias in this query — illustrative)
    WHERE fo.vintage_date = (
        SELECT MAX(vintage_date) FROM marts.fact_macro_observation fo2
        WHERE fo2.series_sk = fo.series_sk
          AND fo2.observation_date = fo.observation_date
    )
),
cpi AS (
    -- CPI All Urban Consumers — YoY change
    SELECT
        fo.observation_date,
        fo.value AS cpi_level,
        LAG(fo.value, 12) OVER (ORDER BY fo.observation_date) AS cpi_12m_ago,
        -- YoY CPI growth
        (fo.value - LAG(fo.value, 12) OVER (ORDER BY fo.observation_date))
            / NULLIF(LAG(fo.value, 12) OVER (ORDER BY fo.observation_date), 0) * 100
                                                              AS cpi_yoy_pct
    FROM marts.fact_macro_observation fo
    JOIN macro_series ms ON ms.asset_sk = fo.series_sk AND ms.ticker = 'CPIAUCSL'
    WHERE fo.vintage_date = (
        SELECT MAX(vintage_date) FROM marts.fact_macro_observation fo2
        WHERE fo2.series_sk = fo.series_sk AND fo2.observation_date = fo.observation_date
    )
),
unemployment AS (
    SELECT fo.observation_date, fo.value AS unrate
    FROM marts.fact_macro_observation fo
    JOIN macro_series ms ON ms.asset_sk = fo.series_sk AND ms.ticker = 'UNRATE'
    WHERE fo.vintage_date = (
        SELECT MAX(vintage_date) FROM marts.fact_macro_observation fo2
        WHERE fo2.series_sk = fo.series_sk AND fo2.observation_date = fo.observation_date
    )
)
SELECT
    f.observation_date,
    ROUND(f.fedfunds_rate::numeric, 3)    AS fedfunds_rate,
    ROUND(c.cpi_yoy_pct::numeric, 2)      AS cpi_yoy_pct,
    ROUND(u.unrate::numeric, 1)           AS unemployment_rate,
    -- Simplified macro regime classification
    CASE
        WHEN c.cpi_yoy_pct > 4.0 AND f.fedfunds_rate > 3.0
             THEN 'overheating'            -- high inflation + tight policy
        WHEN c.cpi_yoy_pct < 2.5 AND u.unrate < 5.0 AND f.fedfunds_rate < 3.0
             THEN 'expansion'             -- goldilocks
        WHEN u.unrate > 6.0 OR c.cpi_yoy_pct < 0
             THEN 'contraction'           -- rising unemployment or deflation risk
        WHEN c.cpi_yoy_pct > 2.5 AND u.unrate < 5.0 AND f.fedfunds_rate < 2.0
             THEN 'late_cycle'            -- low rates but tightening fundamentals
        ELSE 'transition'
    END                                   AS macro_regime
FROM fedfunds f
JOIN cpi c ON c.observation_date = f.observation_date
JOIN unemployment u ON u.observation_date = f.observation_date
WHERE c.cpi_yoy_pct IS NOT NULL  -- need 12m history
ORDER BY f.observation_date DESC
LIMIT 60;  -- Last 5 years monthly

-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 17: FOMC Decisions (Macro) vs BTC Price J+7
-- Requires: enable_macro = true
-- Source tables: marts.fact_macro_observation, marts.fact_market_price,
--               marts.fact_event, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
--   Past correlation between Fed decisions and BTC price does not predict future returns.
-- ============================================================

WITH fedfunds_series AS (
    SELECT asset_sk FROM marts.dim_asset
    WHERE ticker = 'FEDFUNDS' AND asset_kind = 'macro' AND is_current = true LIMIT 1
),
btc AS (
    SELECT asset_sk FROM marts.dim_asset
    WHERE ticker = 'BTC' AND asset_kind = 'crypto' AND is_current = true LIMIT 1
),
fomc_dates AS (
    -- Monthly FOMC observations — detect rate changes vs prior month
    SELECT
        fo.observation_date,
        fo.value                                                 AS rate_after,
        LAG(fo.value) OVER (ORDER BY fo.observation_date)        AS rate_before,
        fo.value - LAG(fo.value) OVER (ORDER BY fo.observation_date)
                                                                 AS rate_change_bps_raw,
        -- Classify decision
        CASE
            WHEN fo.value > LAG(fo.value) OVER (ORDER BY fo.observation_date) THEN 'hike'
            WHEN fo.value < LAG(fo.value) OVER (ORDER BY fo.observation_date) THEN 'cut'
            ELSE 'hold'
        END                                                      AS fomc_decision
    FROM marts.fact_macro_observation fo
    CROSS JOIN fedfunds_series fs
    WHERE fo.series_sk = fs.asset_sk
      AND fo.vintage_date = fo.observation_date  -- real-time vintage
),
btc_price_at_date AS (
    -- BTC close price: at FOMC date, +3d, +7d
    SELECT
        fmp.snapshot_date,
        fmp.close AS btc_close
    FROM marts.fact_market_price fmp
    CROSS JOIN btc
    WHERE fmp.asset_sk = btc.asset_sk
      AND fmp.timeframe = '1d'
),
joined AS (
    SELECT
        fd.observation_date                                      AS fomc_date,
        fd.rate_before,
        fd.rate_after,
        fd.fomc_decision,
        fd.rate_change_bps_raw * 100                             AS rate_change_bps,
        -- BTC price on FOMC date
        p0.btc_close                                             AS btc_price_d0,
        -- BTC price approximately 7 days after
        p7.btc_close                                             AS btc_price_d7,
        -- BTC return J0→J+7
        CASE
            WHEN p0.btc_close > 0 AND p7.btc_close IS NOT NULL
                 THEN ROUND(((p7.btc_close - p0.btc_close) / p0.btc_close * 100)::numeric, 2)
            ELSE NULL
        END                                                      AS btc_return_7d_pct
    FROM fomc_dates fd
    -- Join BTC price on exact FOMC date
    LEFT JOIN btc_price_at_date p0 ON p0.snapshot_date = fd.observation_date
    -- Join BTC price ~7 days later (nearest available trading day ±1d)
    LEFT JOIN LATERAL (
        SELECT btc_close FROM btc_price_at_date
        WHERE snapshot_date BETWEEN fd.observation_date + 6 AND fd.observation_date + 8
        ORDER BY ABS(snapshot_date - (fd.observation_date + 7))
        LIMIT 1
    ) p7 ON true
    WHERE fd.fomc_decision IS NOT NULL
)
SELECT
    fomc_date,
    fomc_decision,
    ROUND(rate_before::numeric, 2)         AS rate_before_pct,
    ROUND(rate_after::numeric, 2)          AS rate_after_pct,
    rate_change_bps,
    ROUND(btc_price_d0::numeric, 2)        AS btc_price_fomc_day,
    ROUND(btc_price_d7::numeric, 2)        AS btc_price_7d_after,
    btc_return_7d_pct,
    -- Simple signal: hike → BTC tends negative historically (no guarantee)
    CASE
        WHEN btc_return_7d_pct IS NOT NULL AND btc_return_7d_pct > 5  THEN 'strong_positive'
        WHEN btc_return_7d_pct IS NOT NULL AND btc_return_7d_pct > 0  THEN 'positive'
        WHEN btc_return_7d_pct IS NOT NULL AND btc_return_7d_pct < -5 THEN 'strong_negative'
        WHEN btc_return_7d_pct IS NOT NULL AND btc_return_7d_pct < 0  THEN 'negative'
        ELSE 'no_data'
    END                                    AS btc_reaction
FROM joined
ORDER BY fomc_date DESC;

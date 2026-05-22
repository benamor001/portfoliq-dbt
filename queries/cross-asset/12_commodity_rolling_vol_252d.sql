-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 12: Commodity Rolling Volatility 252d (WTI + GOLD + SILVER)
-- Requires: enable_commodities = true
-- Source tables: marts.fact_market_price, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

WITH commodity_assets AS (
    SELECT asset_sk, ticker, name
    FROM marts.dim_asset
    WHERE ticker IN ('WTI', 'XAUUSD', 'XAGUSD')
      AND asset_kind = 'commodity'
      AND is_current = true
),
daily_prices AS (
    -- Daily close prices for the last 3 years
    SELECT
        fmp.asset_sk,
        fmp.snapshot_date,
        fmp.close
    FROM marts.fact_market_price fmp
    WHERE fmp.asset_sk IN (SELECT asset_sk FROM commodity_assets)
      AND fmp.timeframe = '1d'
      AND fmp.snapshot_date >= CURRENT_DATE - INTERVAL '3 years'
    ORDER BY fmp.asset_sk, fmp.snapshot_date
),
log_returns AS (
    -- Daily log returns: ln(close_t / close_{t-1})
    SELECT
        asset_sk,
        snapshot_date,
        close,
        LN(close / LAG(close) OVER (PARTITION BY asset_sk ORDER BY snapshot_date)) AS log_return
    FROM daily_prices
),
rolling_vol AS (
    -- STDDEV_SAMP of log returns over last 252 trading days, annualised
    SELECT
        asset_sk,
        snapshot_date,
        close,
        -- Annualised volatility = STDDEV × SQRT(252)
        STDDEV_SAMP(log_return) OVER (
            PARTITION BY asset_sk
            ORDER BY snapshot_date
            ROWS BETWEEN 251 PRECEDING AND CURRENT ROW
        ) * SQRT(252)                    AS annualised_vol_252d,
        -- 30d vol for short-term comparison
        STDDEV_SAMP(log_return) OVER (
            PARTITION BY asset_sk
            ORDER BY snapshot_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) * SQRT(252)                    AS annualised_vol_30d,
        -- Count of observations in window
        COUNT(log_return) OVER (
            PARTITION BY asset_sk
            ORDER BY snapshot_date
            ROWS BETWEEN 251 PRECEDING AND CURRENT ROW
        )                                AS obs_in_window
    FROM log_returns
    WHERE log_return IS NOT NULL  -- exclude first row per asset
)
SELECT
    ca.ticker,
    ca.name,
    rv.snapshot_date,
    rv.close,
    ROUND(rv.annualised_vol_252d::numeric, 4)   AS annualised_vol_252d,
    ROUND(rv.annualised_vol_30d::numeric, 4)    AS annualised_vol_30d,
    rv.obs_in_window,
    -- Volatility regime classification
    CASE
        WHEN rv.annualised_vol_252d < 0.10 THEN 'low_vol'
        WHEN rv.annualised_vol_252d < 0.20 THEN 'moderate_vol'
        WHEN rv.annualised_vol_252d < 0.35 THEN 'high_vol'
        ELSE 'extreme_vol'
    END                                         AS vol_regime
FROM rolling_vol rv
JOIN commodity_assets ca ON ca.asset_sk = rv.asset_sk
WHERE rv.obs_in_window >= 200  -- only report when window is sufficiently populated
ORDER BY rv.snapshot_date DESC, ca.ticker;

-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 18: Asia Stocks — Price in Local Currency + USD Conversion
-- Requires: enable_stocks = true, enable_fx = true
-- Source tables: marts.fact_market_price, marts.dim_asset, marts.dim_currency
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

-- dim_currency is the T-565 Sprint 32 dimension containing ISO-4217 pairs and rates.
-- fx rates sourced from ECB SDW (EUR pairs) and derived cross-rates for non-EUR pairs.

WITH asia_stocks AS (
    -- Select Asia-listed stocks (XTKS = Tokyo, XSHG = Shanghai, XHKG = Hong Kong, etc.)
    SELECT
        da.asset_sk,
        da.ticker,
        da.name,
        da.listing_venue                   AS exchange_mic,
        da.local_currency_iso              -- e.g. 'JPY', 'HKD', 'CNY', 'TWD', 'KRW'
    FROM marts.dim_asset da
    WHERE da.asset_kind = 'stock'
      AND da.is_current = true
      AND da.listing_venue IN ('XTKS', 'XSHG', 'XSHE', 'XHKG', 'XKRX', 'XTAI')
),
latest_local_price AS (
    -- Latest price in local currency (close = local currency close from sat_stock_market_derived)
    SELECT DISTINCT ON (fmp.asset_sk)
        fmp.asset_sk,
        fmp.close            AS close_local,
        fmp.snapshot_date
    FROM marts.fact_market_price fmp
    WHERE fmp.asset_kind = 'stock'
      AND fmp.timeframe = '1d'
    ORDER BY fmp.asset_sk, fmp.snapshot_date DESC
),
fx_latest AS (
    -- Latest FX rate for each currency pair (XXX/USD derived via ECB EUR/XXX + EUR/USD)
    -- dim_currency stores the ISO pair and rate
    SELECT DISTINCT ON (dc.from_currency_iso, dc.to_currency_iso)
        dc.from_currency_iso,
        dc.to_currency_iso,
        dc.rate,
        dc.rate_date
    FROM marts.dim_currency dc
    WHERE dc.to_currency_iso = 'USD'
      AND dc.from_currency_iso IN ('JPY', 'HKD', 'CNY', 'TWD', 'KRW')
    ORDER BY dc.from_currency_iso, dc.to_currency_iso, dc.rate_date DESC
)
SELECT
    ast.ticker,
    ast.name,
    ast.exchange_mic,
    ast.local_currency_iso,
    -- Price in local currency
    ROUND(lp.close_local::numeric, 4)                                   AS close_local_ccy,
    -- FX rate (local → USD)
    fx.rate                                                             AS fx_rate_to_usd,
    fx.rate_date                                                        AS fx_date,
    -- Converted USD price
    CASE
        WHEN fx.rate IS NOT NULL AND fx.rate > 0
             THEN ROUND((lp.close_local * fx.rate)::numeric, 4)
        ELSE NULL
    END                                                                 AS close_usd,
    lp.snapshot_date                                                    AS price_date,
    -- FX staleness flag: warn if FX rate is >3 days old
    CASE
        WHEN lp.snapshot_date - fx.rate_date > 3 THEN true
        ELSE false
    END                                                                 AS fx_rate_stale
FROM asia_stocks ast
JOIN latest_local_price lp ON lp.asset_sk = ast.asset_sk
LEFT JOIN fx_latest fx ON fx.from_currency_iso = ast.local_currency_iso
ORDER BY ast.exchange_mic, close_usd DESC NULLS LAST;

-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 11: YTD Performance — Crypto vs Stock Side-by-Side
-- Requires: enable_stocks = true
-- Source tables: marts.fact_market_price, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

WITH ytd_start AS (
    -- First trading day of current year
    SELECT DATE_TRUNC('year', CURRENT_DATE)::date AS start_date
),
target_assets AS (
    SELECT asset_sk, ticker, name, asset_kind
    FROM marts.dim_asset
    WHERE ticker IN ('BTC', 'ETH', 'SOL', 'AAPL', 'MSFT', 'NVDA', 'SPY')
      AND is_current = true
),
first_price_ytd AS (
    -- First available price at or after YTD start using FIRST_VALUE window function
    SELECT DISTINCT ON (fmp.asset_sk)
        fmp.asset_sk,
        fmp.close     AS price_ytd_start,
        fmp.snapshot_date AS date_ytd_start
    FROM marts.fact_market_price fmp
    CROSS JOIN ytd_start yt
    WHERE fmp.asset_sk IN (SELECT asset_sk FROM target_assets)
      AND fmp.snapshot_date >= yt.start_date
      AND fmp.timeframe = '1d'
    ORDER BY fmp.asset_sk, fmp.snapshot_date ASC
),
latest_price AS (
    -- Latest close (current price)
    SELECT DISTINCT ON (fmp.asset_sk)
        fmp.asset_sk,
        fmp.close     AS price_latest,
        fmp.snapshot_date AS date_latest
    FROM marts.fact_market_price fmp
    WHERE fmp.asset_sk IN (SELECT asset_sk FROM target_assets)
      AND fmp.timeframe = '1d'
    ORDER BY fmp.asset_sk, fmp.snapshot_date DESC
)
SELECT
    ta.ticker,
    ta.name,
    ta.asset_kind,
    fp.price_ytd_start,
    fp.date_ytd_start,
    lp.price_latest,
    lp.date_latest,
    -- YTD return as percentage
    ROUND(
        ((lp.price_latest - fp.price_ytd_start) / NULLIF(fp.price_ytd_start, 0) * 100)::numeric,
        2
    )                                                AS ytd_return_pct,
    -- Rank within asset kind
    ROW_NUMBER() OVER (
        PARTITION BY ta.asset_kind
        ORDER BY (lp.price_latest - fp.price_ytd_start) / NULLIF(fp.price_ytd_start, 0) DESC
    )                                                AS rank_in_kind,
    -- Days elapsed YTD
    lp.date_latest - fp.date_ytd_start              AS trading_days_ytd
FROM target_assets ta
JOIN first_price_ytd fp ON fp.asset_sk = ta.asset_sk
JOIN latest_price lp ON lp.asset_sk = ta.asset_sk
ORDER BY ta.asset_kind, ytd_return_pct DESC;

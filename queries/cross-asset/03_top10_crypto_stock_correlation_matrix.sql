-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 03: Correlation Matrix Top 10 Crypto × Top 10 Stocks
-- Requires: enable_stocks = true
-- Source tables: marts.fact_market_correlation, marts.fact_market_snapshot,
--               marts.fact_market_price, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

WITH top10_crypto AS (
    -- Top 10 crypto by market cap (latest snapshot)
    SELECT
        da.asset_sk,
        da.ticker,
        da.name,
        fms.market_cap_derived_usd,
        ROW_NUMBER() OVER (ORDER BY fms.market_cap_derived_usd DESC NULLS LAST) AS rank
    FROM marts.fact_market_snapshot fms
    JOIN marts.dim_asset da ON da.asset_sk = fms.asset_sk AND da.is_current = true
    WHERE fms.snapshot_date = (SELECT MAX(snapshot_date) FROM marts.fact_market_snapshot)
      AND da.asset_kind = 'crypto'
    LIMIT 10
),
top10_stocks AS (
    -- Top 10 US stocks by recent close price * shares (rough market cap proxy via fundamentals)
    SELECT
        da.asset_sk,
        da.ticker,
        da.name,
        fsf.shares_outstanding * fmp.close  AS mkt_cap_proxy,
        ROW_NUMBER() OVER (ORDER BY fsf.shares_outstanding * fmp.close DESC NULLS LAST) AS rank
    FROM marts.fact_stock_fundamentals fsf
    JOIN marts.dim_asset da ON da.asset_sk = fsf.asset_sk AND da.is_current = true
    JOIN marts.fact_market_price fmp
        ON fmp.asset_sk = da.asset_sk
        AND fmp.snapshot_date = (SELECT MAX(snapshot_date) FROM marts.fact_market_price WHERE asset_kind = 'stock')
    WHERE da.asset_kind = 'stock'
      AND fsf.period_end_date = (
          SELECT MAX(period_end_date) FROM marts.fact_stock_fundamentals fsf2
          WHERE fsf2.asset_sk = da.asset_sk
      )
    LIMIT 10
),
all_pairs AS (
    -- Generate all crypto × stock pairs
    SELECT
        c.asset_sk   AS asset_sk_crypto,
        c.ticker     AS ticker_crypto,
        s.asset_sk   AS asset_sk_stock,
        s.ticker     AS ticker_stock
    FROM top10_crypto c
    CROSS JOIN top10_stocks s
),
corr_lookup AS (
    -- Fetch 90d Pearson correlation for each pair from fact_market_correlation
    -- fact_market_correlation uses canonical ordering asset_sk_a < asset_sk_b
    SELECT
        LEAST(ap.asset_sk_crypto, ap.asset_sk_stock)    AS sk_a,
        GREATEST(ap.asset_sk_crypto, ap.asset_sk_stock) AS sk_b,
        ap.ticker_crypto,
        ap.ticker_stock,
        fmc.pearson_90d,
        fmc.snapshot_date
    FROM all_pairs ap
    JOIN marts.fact_market_correlation fmc
        ON fmc.asset_sk_a = LEAST(ap.asset_sk_crypto, ap.asset_sk_stock)
       AND fmc.asset_sk_b = GREATEST(ap.asset_sk_crypto, ap.asset_sk_stock)
       AND fmc.snapshot_date = (SELECT MAX(snapshot_date) FROM marts.fact_market_correlation)
)
-- Pivot as matrix row: each crypto ticker, each stock as columns would require dynamic SQL.
-- Here we return the flat table for BI tool pivot.
SELECT
    ticker_crypto,
    ticker_stock,
    ROUND(pearson_90d::numeric, 3)   AS pearson_90d,
    snapshot_date
FROM corr_lookup
ORDER BY ticker_crypto, ticker_stock;

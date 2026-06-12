-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 10: fact_market_price Polymorphe — All Asset Kinds in 1 Query
-- Requires: enable_stocks = true, enable_etf = true, enable_commodities = true, enable_fx = true
-- Source tables: marts.fact_market_price, marts.dim_asset, marts.dim_asset_kind
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

-- This is the showcase query for fact_market_price polymorphism.
-- One query returns latest price for one representative asset of each kind.

WITH representative_assets AS (
    -- One asset per kind for illustration
    SELECT asset_sk, ticker, name, asset_kind, listing_venue
    FROM marts.dim_asset
    WHERE (ticker = 'BTC'     AND asset_kind = 'crypto')
       OR (ticker = 'AAPL'    AND asset_kind = 'stock')
       OR (ticker = 'SPY'     AND asset_kind = 'etf')
       OR (ticker = 'XAUUSD'  AND asset_kind = 'commodity')
       OR (ticker = 'EURUSD'  AND asset_kind = 'fx')
      AND is_current = true
),
latest_price AS (
    -- For each asset: latest available price row
    SELECT DISTINCT ON (fmp.asset_sk)
        fmp.asset_sk,
        fmp.asset_kind,
        fmp.listing_venue,
        fmp.ts,
        fmp.snapshot_date,
        fmp.timeframe,
        fmp.open,
        fmp.high,
        fmp.low,
        fmp.close,
        fmp.volume,
        fmp.venues_count,
        fmp.methodology_version
    FROM marts.fact_market_price fmp
    WHERE fmp.asset_sk IN (SELECT asset_sk FROM representative_assets)
    ORDER BY fmp.asset_sk, fmp.ts DESC
)
SELECT
    -- Asset identification
    ra.ticker,
    ra.name,
    -- Conformed asset kind from dim_asset_kind
    dak.label                               AS asset_kind_label,
    ra.listing_venue,
    -- Price (close is the contract — NEVER NULL)
    lp.close                                AS price,
    -- OHLCV fields: only populated for stocks
    lp.open,
    lp.high,
    lp.low,
    lp.volume,
    -- Crypto-specific
    lp.venues_count                         AS consensus_venues,
    -- Timeframe
    lp.timeframe,
    lp.ts                                   AS price_ts,
    lp.snapshot_date,
    lp.methodology_version
FROM latest_price lp
JOIN representative_assets ra ON ra.asset_sk = lp.asset_sk
JOIN marts.dim_asset_kind dak ON dak.asset_kind_key = lp.asset_kind
ORDER BY dak.sort_order;  -- crypto=1, stock=2, etf=3, commodity=4, fx=5

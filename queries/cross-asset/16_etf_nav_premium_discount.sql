-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 16: ETF NAV Premium/Discount vs Market Price
-- Requires: enable_etf = true
-- Source tables: marts.fact_market_price, marts.fact_etf_holdings, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

-- NOTE: fact_etf_holdings contains nav_usd via sat_etf_nav
-- fact_market_price for ETFs uses sat_etf_nav.nav_usd as the 'close' column.
-- This query computes the spread between intraday market price (if available)
-- and end-of-day NAV using the same snapshot date.

WITH etf_universe AS (
    SELECT asset_sk, ticker, name, listing_venue
    FROM marts.dim_asset
    WHERE asset_kind = 'etf' AND is_current = true
),
etf_price_daily AS (
    -- Market price from fact_market_price (using 1d timeframe = closing NAV)
    SELECT
        fmp.asset_sk,
        fmp.snapshot_date,
        fmp.close         AS market_price_usd,
        fmp.methodology_version
    FROM marts.fact_market_price fmp
    WHERE fmp.asset_kind = 'etf'
      AND fmp.timeframe = '1d'
      AND fmp.snapshot_date >= CURRENT_DATE - INTERVAL '90 days'
),
etf_nav_daily AS (
    -- NAV from fact_etf_holdings (sat_etf_nav grain: etf_asset_hk, nav_date)
    -- We join on snapshot_month = date_trunc('month', snapshot_date) for monthly NAV
    -- For daily NAV, use fact_market_price directly (NAV is the 'close' for ETFs).
    -- Premium/discount = (market_price - nav) / nav * 100
    -- Since for ETFs close = nav_usd (from sat_etf_nav), we use a 1-month lag to
    -- approximate end-of-month NAV vs current price.
    SELECT
        feh.etf_asset_sk,
        feh.snapshot_month,
        -- Aggregate NAV: sum of constituent market values / shares outstanding (approx)
        SUM(feh.market_value_usd)   AS total_portfolio_value_usd,
        SUM(feh.weight_pct)         AS total_weight_pct
    FROM marts.fact_etf_holdings feh
    WHERE feh.snapshot_month >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '90 days')::date
    GROUP BY feh.etf_asset_sk, feh.snapshot_month
)
SELECT
    eu.ticker,
    eu.name,
    eu.listing_venue,
    epd.snapshot_date,
    ROUND(epd.market_price_usd::numeric, 4)           AS market_price_usd,
    -- Premium/discount relative to prior month-end NAV (approximate)
    -- In production: use intraday iNAV feed for real-time premium/discount
    end_nav.total_portfolio_value_usd,
    CASE
        WHEN end_nav.total_portfolio_value_usd IS NOT NULL AND epd.market_price_usd IS NOT NULL
             THEN ROUND(
                 ((epd.market_price_usd - end_nav.total_portfolio_value_usd)
                      / NULLIF(end_nav.total_portfolio_value_usd, 0) * 100)::numeric, 4
             )
        ELSE NULL
    END                                                AS premium_discount_pct,
    -- Classify premium/discount
    CASE
        WHEN (epd.market_price_usd - end_nav.total_portfolio_value_usd)
                 / NULLIF(end_nav.total_portfolio_value_usd, 0) > 0.005
             THEN 'premium'
        WHEN (epd.market_price_usd - end_nav.total_portfolio_value_usd)
                 / NULLIF(end_nav.total_portfolio_value_usd, 0) < -0.005
             THEN 'discount'
        ELSE 'at_par'
    END                                                AS nav_status,
    epd.methodology_version
FROM etf_universe eu
JOIN etf_price_daily epd ON epd.asset_sk = eu.asset_sk
LEFT JOIN etf_nav_daily end_nav
    ON end_nav.etf_asset_sk = eu.asset_sk
   AND end_nav.snapshot_month = DATE_TRUNC('month', epd.snapshot_date)::date
ORDER BY eu.ticker, epd.snapshot_date DESC;

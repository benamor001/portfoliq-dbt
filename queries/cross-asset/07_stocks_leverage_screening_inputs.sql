-- ============================================================
-- portfoliq-dbt — Query 07: US Stocks — Leverage Screening Input (debt / market cap)
-- Requires: enable_stocks = true
-- Source tables: marts.fact_stock_fundamentals, marts.fact_market_price, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
--
-- D-166 / AMF-001 — IMPORTANT (this is a PUBLIC package):
--   portfolIQ provides RAW financial inputs only (here: a debt-to-market-cap
--   ratio from SEC filings + consensus price). It does NOT serve any compliance
--   VERDICT or per-threshold pass/fail. Applying the DJIM 33% (or any) threshold
--   and reaching a verdict is the consumer's responsibility.
-- ============================================================

WITH latest_fundamentals AS (
    -- Most recent annual filing (10-K) per stock
    SELECT DISTINCT ON (asset_sk)
        asset_sk,
        period_end_date,
        filing_type,
        eps_basic,
        eps_diluted,
        revenue_usd,
        net_income_usd,
        ebitda_usd,
        total_debt_usd,
        cash_equivalents_usd,
        shares_outstanding,
        accession_number
    FROM marts.fact_stock_fundamentals
    WHERE filing_type = '10-K'  -- Annual filing for DJIM screening
    ORDER BY asset_sk, period_end_date DESC
),
latest_price AS (
    -- Latest close price for market cap calculation
    SELECT DISTINCT ON (asset_sk)
        asset_sk,
        close                              AS latest_close_usd,
        snapshot_date
    FROM marts.fact_market_price
    WHERE asset_kind = 'stock'
    ORDER BY asset_sk, snapshot_date DESC
),
djim_inputs AS (
    SELECT
        da.asset_sk,
        da.ticker,
        da.name,
        da.listing_venue                   AS exchange_mic,
        -- Market cap = latest close × shares outstanding
        lp.latest_close_usd * lf.shares_outstanding    AS market_cap_usd,
        lf.total_debt_usd,
        lf.revenue_usd,
        -- DJIM ratio 1: debt / (trailing 36m avg market cap) — approx with current
        CASE
            WHEN lp.latest_close_usd * lf.shares_outstanding > 0
                 THEN lf.total_debt_usd / (lp.latest_close_usd * lf.shares_outstanding)
            ELSE NULL
        END                                            AS debt_to_market_cap,
        lf.period_end_date                             AS filing_date,
        lp.snapshot_date                               AS price_date,
        lf.accession_number
    FROM latest_fundamentals lf
    JOIN marts.dim_asset da ON da.asset_sk = lf.asset_sk AND da.is_current = true
    JOIN latest_price lp ON lp.asset_sk = lf.asset_sk
    WHERE da.asset_kind = 'stock'
)
SELECT
    ticker,
    name,
    exchange_mic,
    ROUND(market_cap_usd::numeric / 1e9, 2)         AS market_cap_bn_usd,
    ROUND(total_debt_usd::numeric / 1e9, 2)         AS total_debt_bn_usd,
    ROUND(debt_to_market_cap::numeric, 4)            AS debt_to_mktcap_ratio,
    filing_date,
    price_date,
    accession_number                                  -- SEC traceability
FROM djim_inputs
ORDER BY market_cap_usd DESC NULLS LAST;

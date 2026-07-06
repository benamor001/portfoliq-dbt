-- ============================================================
-- portfoliq-dbt — Query 09: Screening Inputs — Leverage Ratio (raw, no verdict)
--   Debt / market-cap input, computed from public fundamentals + consensus price.
-- Requires: enable_stocks = true (for stock inputs)
-- Source tables: marts.dim_asset, marts.fact_stock_fundamentals, marts.fact_market_price
--
-- D-166 / AMF-001 — IMPORTANT (this is a PUBLIC package):
--   portfolIQ provides RAW screening INPUTS only (here: a leverage ratio derived
--   from public filings + consensus price). It does NOT serve any compliance
--   VERDICT, compliance boolean, per-standard pass/fail, or cross-standard
--   "agreement" judgment. Applying a published screening standard's threshold and
--   reaching a verdict is the consumer's responsibility.
-- ============================================================

WITH target_assets AS (
    -- Illustrative subset
    SELECT asset_sk, ticker, name, asset_kind
    FROM marts.dim_asset
    WHERE ticker IN ('AAPL', 'MSFT', 'TSLA', 'BTC', 'ETH')
      AND is_current = true
),
latest_fundamentals AS (
    SELECT DISTINCT ON (asset_sk)
        asset_sk, total_debt_usd, revenue_usd, shares_outstanding, period_end_date
    FROM marts.fact_stock_fundamentals
    WHERE filing_type = '10-K'
    ORDER BY asset_sk, period_end_date DESC
),
latest_price AS (
    SELECT DISTINCT ON (asset_sk)
        asset_sk, close AS close_usd, snapshot_date
    FROM marts.fact_market_price
    ORDER BY asset_sk, snapshot_date DESC
)
SELECT
    ta.ticker,
    ta.name,
    ta.asset_kind,
    -- Raw leverage input: total debt / market cap (consumer applies any threshold)
    ROUND(
        (lf.total_debt_usd / NULLIF(lp.close_usd * lf.shares_outstanding, 0))::numeric, 4
    )                                                         AS debt_to_market_cap,
    lf.total_debt_usd,
    lf.shares_outstanding,
    lp.close_usd,
    lp.snapshot_date,
    lf.period_end_date                                        AS filing_date
FROM target_assets ta
LEFT JOIN latest_fundamentals lf ON lf.asset_sk = ta.asset_sk
LEFT JOIN latest_price lp ON lp.asset_sk = ta.asset_sk
ORDER BY ta.ticker;

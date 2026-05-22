-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 09: Multi-Standard Halal Screening Comparison
--   AAOIFI vs DJIM 33% threshold vs Wahed-style inputs — same asset
-- Requires: enable_stocks = true (for stock inputs; crypto works without)
-- Source tables: marts.dim_asset, marts.fact_stock_fundamentals, marts.fact_market_price
-- Disclaimer: Not financial advice. Methodology disclosed. Not a fatwa.
--   PIQ provides raw inputs only. Final verdict is calculated client-side
--   per D-070 §2. Different standards may yield different verdicts.
-- ============================================================

WITH target_assets AS (
    -- Illustrative: compare AAPL, MSFT, TSLA against halal standards
    SELECT asset_sk, ticker, name, asset_kind,
           is_halal_aaoifi, halal_aaoifi_score, sharia_purification_ratio,
           haram_revenue_ratio
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
),
inputs AS (
    SELECT
        ta.ticker,
        ta.name,
        ta.asset_kind,
        -- AAOIFI verdict (PIQ-computed)
        ta.is_halal_aaoifi                                        AS aaoifi_verdict,
        ta.halal_aaoifi_score                                     AS aaoifi_score,
        ta.sharia_purification_ratio                              AS aaoifi_purif_ratio,
        -- DJIM inputs (raw — client computes verdict)
        CASE
            WHEN lf.total_debt_usd IS NOT NULL AND lp.close_usd IS NOT NULL
                 THEN lf.total_debt_usd / NULLIF(lp.close_usd * lf.shares_outstanding, 0)
            ELSE NULL
        END                                                       AS djim_debt_ratio,
        ta.haram_revenue_ratio                                    AS djim_haram_rev_ratio,
        -- DJIM 33% screen (debt threshold)
        CASE
            WHEN lf.total_debt_usd / NULLIF(lp.close_usd * lf.shares_outstanding, 0) < 0.33
                 THEN true
            WHEN lf.total_debt_usd IS NULL THEN NULL  -- crypto: no debt data
            ELSE false
        END                                                       AS djim_debt_screen,
        -- Wahed-style: stricter revenue (<5%) + business activity
        CASE
            WHEN ta.haram_revenue_ratio < 0.05 THEN true
            WHEN ta.haram_revenue_ratio IS NULL THEN NULL
            ELSE false
        END                                                       AS wahed_revenue_screen,
        -- Agreement across standards
        lp.snapshot_date,
        lf.period_end_date                                        AS filing_date
    FROM target_assets ta
    LEFT JOIN latest_fundamentals lf ON lf.asset_sk = ta.asset_sk
    LEFT JOIN latest_price lp ON lp.asset_sk = ta.asset_sk
)
SELECT
    ticker,
    name,
    asset_kind,
    -- AAOIFI column (PIQ verdict)
    aaoifi_verdict,
    ROUND(aaoifi_score::numeric, 3)           AS aaoifi_score,
    ROUND(aaoifi_purif_ratio::numeric, 4)     AS aaoifi_purif_ratio,
    -- DJIM inputs (client applies threshold)
    ROUND(djim_debt_ratio::numeric, 4)        AS djim_debt_ratio,
    ROUND(djim_haram_rev_ratio::numeric, 4)   AS djim_haram_rev_ratio,
    djim_debt_screen,
    -- Wahed screen input
    wahed_revenue_screen,
    -- Convergence: all three methods agree
    CASE
        WHEN aaoifi_verdict = true AND djim_debt_screen = true AND wahed_revenue_screen = true
             THEN 'all_pass'
        WHEN aaoifi_verdict = false AND djim_debt_screen = false AND wahed_revenue_screen = false
             THEN 'all_fail'
        ELSE 'divergent'
    END                                       AS standards_agreement,
    snapshot_date,
    filing_date
FROM inputs
ORDER BY ticker;

-- ============================================================
-- portfoliq-dbt — Query 08: ETF Holdings — Universe Coverage by Weight
-- Requires: enable_etf = true, enable_stocks = true (for constituent mapping)
-- Source tables: marts.fact_etf_holdings, marts.dim_asset
--
-- D-166 / AMF-001 — IMPORTANT (this is a PUBLIC package):
--   portfolIQ does NOT serve a religious- or ethics-compliance VERDICT, nor any
--   compliance boolean, nor an aggregated compliance-weight % or pass/fail. The
--   screening verdict is sovereign to downstream consumers (screening stays consumer-side).
--   This query reports only how much of an ETF's weight maps to the portfolIQ
--   asset universe — a data-coverage metric, NOT a compliance judgment.
-- ============================================================

WITH latest_holdings AS (
    -- Most recent snapshot_month per ETF
    SELECT DISTINCT ON (etf_asset_sk)
        etf_asset_sk,
        snapshot_month,
        SUM(weight_pct) OVER (PARTITION BY etf_asset_sk, snapshot_month) AS total_weight_pct
    FROM marts.fact_etf_holdings
    ORDER BY etf_asset_sk, snapshot_month DESC
),
holdings_detail AS (
    -- All holdings for the latest snapshot, mapped to our universe (no verdict attrs)
    SELECT
        feh.etf_asset_sk,
        feh.constituent_asset_sk,
        feh.constituent_identifier,
        feh.weight_pct,
        feh.market_value_usd,
        feh.snapshot_month
    FROM marts.fact_etf_holdings feh
    JOIN latest_holdings lh ON lh.etf_asset_sk = feh.etf_asset_sk
                            AND lh.snapshot_month = feh.snapshot_month
),
etf_coverage AS (
    -- Aggregate universe coverage per ETF (purely descriptive)
    SELECT
        hd.etf_asset_sk,
        hd.snapshot_month,
        COUNT(*)                                         AS total_holdings,
        COUNT(hd.constituent_asset_sk)                   AS matched_holdings,  -- in our universe
        -- Coverage ratio: % of AUM mapped to our universe
        SUM(CASE WHEN hd.constituent_asset_sk IS NOT NULL THEN hd.weight_pct ELSE 0 END)
            AS mapped_weight_pct
    FROM holdings_detail hd
    GROUP BY hd.etf_asset_sk, hd.snapshot_month
)
SELECT
    da_etf.ticker                                        AS etf_ticker,
    da_etf.name                                          AS etf_name,
    da_etf.listing_venue                                 AS exchange,
    ec.snapshot_month,
    ec.total_holdings,
    ec.matched_holdings,
    ROUND(ec.mapped_weight_pct::numeric, 2)              AS mapped_weight_pct,
    ROUND(
        (ec.matched_holdings::numeric / NULLIF(ec.total_holdings, 0) * 100), 2
    )                                                    AS matched_holdings_pct
FROM etf_coverage ec
JOIN marts.dim_asset da_etf ON da_etf.asset_sk = ec.etf_asset_sk AND da_etf.is_current = true
ORDER BY ec.mapped_weight_pct DESC NULLS LAST;

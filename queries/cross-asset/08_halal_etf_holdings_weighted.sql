-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 08: ETF Halal Score — Weighted by Holdings
-- Requires: enable_etf = true, enable_stocks = true (for constituent halal attrs)
-- Source tables: marts.fact_etf_holdings, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed. Not a fatwa.
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
    -- All holdings for the latest snapshot, with constituent halal status
    SELECT
        feh.etf_asset_sk,
        feh.constituent_asset_sk,
        feh.constituent_identifier,
        feh.weight_pct,
        feh.market_value_usd,
        feh.snapshot_month,
        -- Constituent halal attributes (NULL if constituent not in dim_asset)
        da_c.is_halal_aaoifi,
        da_c.haram_revenue_ratio
    FROM marts.fact_etf_holdings feh
    JOIN latest_holdings lh ON lh.etf_asset_sk = feh.etf_asset_sk
                            AND lh.snapshot_month = feh.snapshot_month
    LEFT JOIN marts.dim_asset da_c
        ON da_c.asset_sk = feh.constituent_asset_sk AND da_c.is_current = true
),
etf_halal_score AS (
    -- Aggregate weighted halal score per ETF
    SELECT
        hd.etf_asset_sk,
        hd.snapshot_month,
        COUNT(*)                                         AS total_holdings,
        COUNT(hd.constituent_asset_sk)                   AS matched_holdings,  -- in our universe
        -- Weighted halal coverage (only on matched holdings)
        SUM(CASE WHEN hd.is_halal_aaoifi = true THEN hd.weight_pct ELSE 0 END)
            AS halal_weight_pct,
        -- Weighted haram revenue (for purification estimate)
        SUM(COALESCE(hd.haram_revenue_ratio, 0) * hd.weight_pct / 100.0)
            AS weighted_haram_revenue_ratio,
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
    ehs.snapshot_month,
    ehs.total_holdings,
    ehs.matched_holdings,
    ROUND(ehs.mapped_weight_pct::numeric, 2)             AS mapped_weight_pct,
    ROUND(ehs.halal_weight_pct::numeric, 2)              AS halal_weight_pct,
    -- Halal coverage as % of mapped AUM (excludes unmatched holdings)
    ROUND(
        (ehs.halal_weight_pct / NULLIF(ehs.mapped_weight_pct, 0) * 100)::numeric, 2
    )                                                    AS halal_pct_of_mapped,
    ROUND(ehs.weighted_haram_revenue_ratio::numeric, 4)  AS weighted_haram_revenue_ratio,
    -- Simple pass/fail: >90% of mapped AUM halal
    (ehs.halal_weight_pct / NULLIF(ehs.mapped_weight_pct, 0) * 100) > 90
                                                         AS preliminary_halal_pass
FROM etf_halal_score ehs
JOIN marts.dim_asset da_etf ON da_etf.asset_sk = ehs.etf_asset_sk AND da_etf.is_current = true
ORDER BY ehs.halal_weight_pct DESC NULLS LAST;

-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 14: ETF Holdings — Top 10 + Cumulative Weight + HHI
-- Requires: enable_etf = true
-- Source tables: marts.fact_etf_holdings, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

WITH target_etf AS (
    -- Replace 'QQQ' with any ETF ticker in your universe
    SELECT asset_sk FROM marts.dim_asset
    WHERE ticker = 'QQQ' AND asset_kind = 'etf' AND is_current = true LIMIT 1
),
latest_snapshot AS (
    -- Most recent holdings snapshot for the ETF
    SELECT MAX(snapshot_month) AS snapshot_month
    FROM marts.fact_etf_holdings feh
    CROSS JOIN target_etf te
    WHERE feh.etf_asset_sk = te.asset_sk
),
holdings_ranked AS (
    SELECT
        feh.constituent_identifier,
        da_c.ticker                                         AS constituent_ticker,
        da_c.name                                           AS constituent_name,
        feh.weight_pct,
        feh.market_value_usd,
        feh.shares_held,
        -- Rank by weight
        ROW_NUMBER() OVER (ORDER BY feh.weight_pct DESC NULLS LAST)  AS weight_rank,
        -- Cumulative weight (window sum)
        SUM(feh.weight_pct) OVER (
            ORDER BY feh.weight_pct DESC NULLS LAST
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                   AS cumulative_weight_pct,
        -- HHI contribution: weight^2 (sum gives HHI index)
        POWER(feh.weight_pct / 100.0, 2)                   AS hhi_contribution
    FROM marts.fact_etf_holdings feh
    CROSS JOIN target_etf te
    JOIN latest_snapshot ls ON feh.snapshot_month = ls.snapshot_month
    LEFT JOIN marts.dim_asset da_c
        ON da_c.asset_sk = feh.constituent_asset_sk AND da_c.is_current = true
    WHERE feh.etf_asset_sk = te.asset_sk
),
hhi_total AS (
    -- Herfindahl-Hirschman Index (0=fully diversified, 1=fully concentrated)
    SELECT ROUND(SUM(hhi_contribution)::numeric, 6) AS hhi_index
    FROM holdings_ranked
)
SELECT
    hr.weight_rank,
    COALESCE(hr.constituent_ticker, hr.constituent_identifier) AS identifier,
    hr.constituent_name,
    ROUND(hr.weight_pct::numeric, 4)                    AS weight_pct,
    ROUND(hr.cumulative_weight_pct::numeric, 2)         AS cumulative_weight_pct,
    hr.market_value_usd,
    -- Concentration tier
    CASE
        WHEN hr.weight_rank <= 5  THEN 'top_5'
        WHEN hr.weight_rank <= 10 THEN 'top_10'
        ELSE 'tail'
    END                                                  AS concentration_tier,
    -- HHI index (same for all rows — reported on each for BI filtering)
    ht.hhi_index,
    CASE
        WHEN ht.hhi_index > 0.25 THEN 'highly_concentrated'
        WHEN ht.hhi_index > 0.10 THEN 'moderately_concentrated'
        ELSE 'diversified'
    END                                                  AS hhi_classification
FROM holdings_ranked hr
CROSS JOIN hhi_total ht
WHERE hr.weight_rank <= 10  -- Top 10 only; remove filter for full list
ORDER BY hr.weight_rank;

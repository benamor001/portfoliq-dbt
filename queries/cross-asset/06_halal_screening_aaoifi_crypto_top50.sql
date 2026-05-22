-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 06: Top 50 Crypto — AAOIFI Halal Screening + Purification Ratio
-- Requires: (no enable_* var — crypto is default)
-- Source tables: marts.dim_asset, marts.fact_market_snapshot
-- Disclaimer: Not financial advice. Methodology disclosed.
--   Halal classification is based on disclosed methodology only.
--   Not a fatwa. Consult a qualified Islamic finance scholar for rulings.
-- ============================================================

WITH latest_snapshot AS (
    -- One row per asset: latest snapshot_date
    SELECT DISTINCT ON (asset_sk)
        asset_sk,
        snapshot_date,
        market_cap_derived_usd,
        price_consensus_usd
    FROM marts.fact_market_snapshot
    ORDER BY asset_sk, snapshot_date DESC
),
ranked AS (
    -- Rank by market cap to get top 50
    SELECT
        ls.asset_sk,
        ls.snapshot_date,
        ls.market_cap_derived_usd,
        ls.price_consensus_usd,
        ROW_NUMBER() OVER (ORDER BY ls.market_cap_derived_usd DESC NULLS LAST) AS mktcap_rank
    FROM latest_snapshot ls
)
SELECT
    r.mktcap_rank,
    da.ticker,
    da.name,
    da.tier                                               AS portfoliq_tier,
    -- Halal attributes from dim_asset (populated by sat_asset_halal)
    da.is_halal_aaoifi,
    da.halal_aaoifi_score,
    da.sharia_purification_ratio,
    -- Interpretation per AAOIFI standard
    CASE
        WHEN da.is_halal_aaoifi = true  THEN 'Permissible'
        WHEN da.is_halal_aaoifi = false THEN 'Not Permissible'
        ELSE 'Pending Review'
    END                                                   AS aaoifi_verdict,
    -- Purification guidance (round up to nearest cent)
    CASE
        WHEN da.sharia_purification_ratio IS NOT NULL
         AND da.sharia_purification_ratio > 0
             THEN ROUND((r.price_consensus_usd * da.sharia_purification_ratio)::numeric, 4)
        ELSE NULL
    END                                                   AS purification_per_token_usd,
    r.market_cap_derived_usd,
    r.price_consensus_usd,
    r.snapshot_date
FROM ranked r
JOIN marts.dim_asset da ON da.asset_sk = r.asset_sk AND da.is_current = true
WHERE r.mktcap_rank <= 50
ORDER BY r.mktcap_rank;

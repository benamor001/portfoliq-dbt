-- ============================================================
-- portfoliq-dbt — Query 06: Top 50 Crypto by Market Cap (consensus-derived)
-- Requires: (no enable_* var — crypto is default)
-- Source tables: marts.dim_asset, marts.fact_market_snapshot
-- Disclaimer: Not financial advice. Methodology disclosed.
--
-- D-166 / AMF-001 — IMPORTANT (this is a PUBLIC package):
--   portfolIQ does NOT serve a religious- or ethics-compliance VERDICT, nor any
--   compliance boolean. The screening verdict is sovereign to downstream
--   consumers (screening stays consumer-side). This query therefore exposes market data only.
--   Purification ratios (methodological inputs, standard disclosed at portfoliq.io/methodology) are served via the
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
    r.market_cap_derived_usd,
    r.price_consensus_usd,
    r.snapshot_date
FROM ranked r
JOIN marts.dim_asset da ON da.asset_sk = r.asset_sk AND da.is_current = true
WHERE r.mktcap_rank <= 50
ORDER BY r.mktcap_rank;

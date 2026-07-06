-- ============================================================
-- portfolIQ dbt pack — Example Query 04
-- Title: Top 10 DeFi Protocols by TVL (Latest Snapshot)
-- Business context: Rank DeFi protocols by self-calculated Total Value
--   Locked at yesterday's snapshot. TVL is a primary health indicator for
--   DeFi protocols: it reflects capital trust and protocol stickiness.
--   TVL is portfolIQ self-calculated from on-chain pool balances
--   (NOT redistributed from DeFiLlama).
-- Suggested BI tool: Metabase (table), Tableau (bar chart)
-- Tables: star_public.fact_protocol_tvl
-- Filters: snapshot_date = yesterday (prevents full scan)
-- Not financial advice. Methodology disclosed.
-- ============================================================

SELECT
    fpt.protocol_id,
    fpt.tvl_usd,
    fpt.tvl_change_1d_pct,
    fpt.tvl_change_7d_pct,
    fpt.methodology_version
FROM star_public.fact_protocol_tvl  fpt
WHERE
    fpt.snapshot_date = CURRENT_DATE - INTERVAL '1 day'
    AND fpt.tvl_usd   IS NOT NULL
ORDER BY fpt.tvl_usd DESC
LIMIT 10;

-- NOTE: dim_protocol is not included in portfolIQ v1 (protocol_id = DeFiLlama slug BK).
-- Join to your own protocol reference table if needed.

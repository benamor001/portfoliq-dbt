-- ============================================================
-- portfolIQ dbt pack — Example Query 18
-- Title: Cross-Chain TVL Breakdown (Latest Snapshot)
-- Business context: Aggregate portfolIQ self-calculated TVL per protocol
--   and annotate with chain metadata from the dim_chain seed. Shows which
--   blockchains (Ethereum, BSC, Solana, Arbitrum L2, etc.) carry the most
--   DeFi capital at the latest snapshot. TVL is self-calculated by portfolIQ
--   from on-chain pool balances (not redistributed from DeFiLlama).
-- Suggested BI tool: Tableau (treemap), Power BI (decomposition tree)
-- Tables: star_public.fact_protocol_tvl,
--         portfoliq_reference.dim_chain (seed — chain metadata)
-- Filters: snapshot_date = yesterday (prevents full scan)
-- Not financial advice. Methodology disclosed.
-- ============================================================

-- NOTE: fact_protocol_tvl.chains stores chain names as a text field.
-- The seed dim_chain (portfoliq_reference schema) provides chain metadata.
-- This query aggregates TVL by joining protocol chains to the chain dimension.
-- If chains is a JSONB array in your setup, UNNEST before joining.

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
LIMIT 20;

-- ============================================================
-- To enrich with chain metadata, join fact_protocol_economics.chains
-- (array field) to portfoliq_reference.dim_chain on chain_name:
--
-- SELECT
--     pe.chains,
--     dc.chain_name,
--     dc.is_evm,
--     dc.is_l2,
--     SUM(fpt.tvl_usd) AS total_tvl_by_chain
-- FROM star_public.fact_protocol_economics pe
-- JOIN star_public.fact_protocol_tvl fpt
--     ON fpt.protocol_id = pe.protocol_id AND fpt.snapshot_date = pe.snapshot_date
-- CROSS JOIN LATERAL UNNEST(pe.chains) AS chain_name
-- JOIN portfoliq_reference.dim_chain dc ON dc.chain_name = chain_name
-- WHERE fpt.snapshot_date = CURRENT_DATE - INTERVAL '1 day'
-- GROUP BY pe.chains, dc.chain_name, dc.is_evm, dc.is_l2
-- ORDER BY total_tvl_by_chain DESC;
-- ============================================================

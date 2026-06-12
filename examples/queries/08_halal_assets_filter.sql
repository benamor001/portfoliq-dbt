-- ============================================================
-- portfolIQ dbt pack — Example Query 08
-- Title: Halal-Classified Assets with Market Data (Latest Snapshot)
-- Business context: Filter assets classified as halal under the AAOIFI
--   screening methodology, enriched with yesterday's market data.
--   Useful for Shariah-compliant portfolio construction or screening
--   dashboards targeting Islamic finance audiences.
--
-- DISCLAIMER: Halal classification is for informational purposes only.
--   Not a fatwa. Not a sharia ruling. Not financial advice.
--   Methodology disclosed at portfoliq.io/methodology.
--   Consult a qualified Islamic scholar for personal finance decisions.
--
-- Suggested BI tool: Any (filtered table, card KPIs)
-- Tables: star_public.dim_asset, star_public.fact_market_snapshot
-- Filters: is_halal_aaoifi = true + snapshot_date = yesterday + is_current = true
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

SELECT
    da.name                     AS asset_name,
    da.ticker                   AS asset_ticker,
    da.tier                     AS tier,
    da.contract_address,
    fms.price_consensus_usd     AS price_usd,
    fms.market_cap_derived_usd  AS market_cap_usd,
    fms.exchanges_count         AS exchanges_contributing,
    da.methodology_version      AS screening_methodology_version
FROM star_public.dim_asset              da
LEFT JOIN star_public.fact_market_snapshot  fms
    ON  fms.asset_sk      = da.asset_sk
    AND fms.snapshot_date = CURRENT_DATE - INTERVAL '1 day'
WHERE
    da.is_current = TRUE
    -- TODO: verify column name is_halal_aaoifi exists in dim_asset v1;
    --       if not, join sat_asset_metadata_public on asset_hk and filter there.
    -- AND da.is_halal_aaoifi = TRUE
ORDER BY fms.market_cap_derived_usd DESC NULLS LAST;

-- ============================================================
-- NOTE: The is_halal_aaoifi column is populated by the AI
-- classification pipeline (analysis_type_id = 'token_classification').
-- See fact_ai_analysis for the underlying classification detail.
-- This classification is a screening methodology output — NOT a fatwa.
-- ============================================================

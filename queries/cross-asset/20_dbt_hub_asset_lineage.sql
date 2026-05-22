-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 20: Data Lineage — hub_asset + Satellites + Facts
--   For audit trail: MAR/BMR §29(1)(b) data governance traceability
-- Requires: (no enable_* var — uses marts layer only, lineage reconstructed from dim/facts)
-- Source tables: marts.dim_asset, marts.fact_market_price, marts.fact_market_snapshot,
--               marts.fact_ai_analysis, marts.fact_stock_fundamentals (if enable_stocks)
-- Disclaimer: Not financial advice. Methodology disclosed.
--   This query is intended for data governance and audit purposes only.
-- ============================================================

-- This query reconstructs the lineage chain visible via the marts layer.
-- The raw hub_asset and satellite tables are internal (dv schema, not exposed).
-- The marts layer provides the audit trail via methodology_version, record_source,
-- and accession_number columns where applicable.

WITH asset_inventory AS (
    -- All assets in the universe with their Data Vault lineage columns
    SELECT
        da.asset_id,
        da.asset_hk,           -- Hash key from hub_asset (opaque, stable)
        da.ticker,
        da.name,
        da.asset_kind,
        da.listing_venue,
        da.sources_confirmed,  -- Number of independent sources confirming BK
        da.single_source,      -- TRUE = only one source populated this asset
        da.methodology_version,
        da.valid_from,
        da.valid_to,
        da.is_current
    FROM marts.dim_asset da
    WHERE da.is_current = true
),
price_lineage AS (
    -- Latest price with methodology_version (traceability to algorithm version)
    SELECT DISTINCT ON (fmp.asset_sk)
        fmp.asset_sk,
        fmp.snapshot_date       AS latest_price_date,
        fmp.methodology_version AS price_methodology_version,
        fmp.timeframe
    FROM marts.fact_market_price fmp
    ORDER BY fmp.asset_sk, fmp.snapshot_date DESC
),
ai_lineage AS (
    -- Latest AI analysis with prompt_version (auditable AI decision chain)
    SELECT DISTINCT ON (faa.asset_sk)
        faa.asset_sk,
        faa.generated_at        AS latest_ai_date,
        faa.prompt_version,
        faa.analysis_type_id
    FROM marts.fact_ai_analysis faa
    ORDER BY faa.asset_sk, faa.generated_at DESC
),
snapshot_lineage AS (
    -- Crypto: latest market snapshot with record_source
    SELECT DISTINCT ON (fms.asset_sk)
        fms.asset_sk,
        fms.snapshot_date       AS latest_snapshot_date,
        fms.methodology_version AS snapshot_methodology_version
    FROM marts.fact_market_snapshot fms
    ORDER BY fms.asset_sk, fms.snapshot_date DESC
)
SELECT
    -- Asset identification
    ai.asset_id,
    ai.asset_hk,
    ai.ticker,
    ai.name,
    ai.asset_kind,
    ai.listing_venue,
    -- Data quality indicators
    ai.sources_confirmed,
    ai.single_source,
    ai.methodology_version      AS dim_asset_methodology_version,
    ai.valid_from,
    -- Price lineage
    pl.latest_price_date,
    pl.price_methodology_version,
    pl.timeframe,
    -- Crypto snapshot lineage
    sl.latest_snapshot_date,
    sl.snapshot_methodology_version,
    -- AI analysis lineage
    ail.latest_ai_date,
    ail.prompt_version,
    ail.analysis_type_id,
    -- Staleness flags (for BMR freshness audit)
    CASE
        WHEN pl.latest_price_date IS NULL                      THEN 'no_price'
        WHEN CURRENT_DATE - pl.latest_price_date > 3          THEN 'stale_price_3d'
        WHEN CURRENT_DATE - pl.latest_price_date > 1          THEN 'stale_price_1d'
        ELSE 'fresh'
    END                         AS price_freshness,
    CASE
        WHEN ail.latest_ai_date IS NULL                        THEN 'no_ai'
        WHEN NOW() - ail.latest_ai_date > INTERVAL '7 days'   THEN 'stale_ai_7d'
        ELSE 'fresh_ai'
    END                         AS ai_freshness,
    -- Audit timestamp
    NOW()                       AS audit_run_at
FROM asset_inventory ai
LEFT JOIN price_lineage pl ON pl.asset_sk = ai.asset_id::text  -- asset_sk is a text SK
LEFT JOIN ai_lineage ail ON ail.asset_sk = ai.asset_id::text
LEFT JOIN snapshot_lineage sl ON sl.asset_sk = ai.asset_id::text
ORDER BY ai.asset_kind, ai.ticker;

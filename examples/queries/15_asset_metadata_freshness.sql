-- ============================================================
-- portfolIQ dbt pack — Example Query 15
-- Title: Asset Metadata Freshness — Data Age per Active Asset
-- Business context: Monitor how fresh the asset metadata is for each
--   active asset in the pipeline. Stale metadata (data_age > 24h) may
--   indicate an ingestion failure or a source outage. Essential for
--   data quality monitoring and SLA tracking.
-- Suggested BI tool: Metabase (monitoring table with thresholds)
-- Tables: star_public.dim_asset
-- Filters: is_current = true + is_active implicit (valid_to IS NULL)
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

SELECT
    da.name                                         AS asset_name,
    da.ticker                                       AS asset_ticker,
    da.tier,
    da.valid_from                                   AS metadata_loaded_at,
    CURRENT_TIMESTAMP - da.valid_from               AS data_age,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - da.valid_from)) / 3600
                                                    AS data_age_hours,
    da.sources_confirmed,
    da.single_source                                AS is_single_source,
    da.methodology_version
FROM star_public.dim_asset  da
WHERE
    da.is_current = TRUE
ORDER BY
    data_age DESC;

-- TIP: Flag rows where data_age_hours > 25 — those assets may have stale metadata.
-- Use this in a Metabase alert: WHERE EXTRACT(EPOCH FROM ...) / 3600 > 25

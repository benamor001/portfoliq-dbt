-- ============================================================
-- portfolIQ dbt pack — Example Query 16
-- Title: AI Analysis Production Monitoring (Last 30 Days)
-- Business context: Track the volume of AI-generated analyses by type
--   and by model (Haiku vs Sonnet) over the past 30 days. Useful for
--   internal monitoring of the AI pipeline throughput, model distribution,
--   and prompt version rollouts. Note: cost_usd_micros is intentionally
--   excluded from the public Star Schema (internal metric only).
-- Suggested BI tool: Metabase (admin monitoring dashboard)
-- Tables: star_public.fact_ai_analysis, star_public.dim_analysis_type
-- Filters: generated_date range last 30 days (prevents full scan)
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

SELECT
    faa.analysis_type_id,
    dat.analysis_type_label,
    dat.model_default           AS default_model_for_type,
    dat.refresh_cadence,
    faa.model_id                AS ai_model_used,
    faa.prompt_version,
    COUNT(*)                    AS analyses_count,
    MIN(faa.generated_date)     AS first_generated,
    MAX(faa.generated_date)     AS last_generated
FROM star_public.fact_ai_analysis  faa
LEFT JOIN star_public.dim_analysis_type  dat
    ON dat.analysis_type_id = faa.analysis_type_id
WHERE
    faa.generated_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    faa.analysis_type_id,
    dat.analysis_type_label,
    dat.model_default,
    dat.refresh_cadence,
    faa.model_id,
    faa.prompt_version
ORDER BY
    faa.analysis_type_id,
    faa.prompt_version,
    faa.model_id;

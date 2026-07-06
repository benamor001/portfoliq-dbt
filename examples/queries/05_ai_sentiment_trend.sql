-- ============================================================
-- portfolIQ dbt pack — Example Query 05
-- Title: AI Sentiment Trend for a Given Asset (Last 30 Days)
-- Business context: Track the evolution of AI-generated sentiment scores
--   for a specific asset. Useful for monitoring narrative shifts and
--   correlating sentiment with price action. AI-generated content —
--   not financial advice.
-- Suggested BI tool: Power BI (line chart with annotations)
-- Tables: star_public.fact_ai_analysis, star_public.dim_asset
-- Filters: asset ticker + generated_date last 30 days + analysis_type = sentiment_score
-- Not financial advice. Methodology disclosed.
-- ============================================================

-- Replace 'BTC' with any ticker available in dim_asset.
SELECT
    faa.generated_date,
    da.name                 AS asset_name,
    da.ticker               AS asset_ticker,
    faa.analysis_type_id,
    faa.model_id            AS ai_model,
    faa.prompt_version,
    -- Extract numeric score from JSONB payload (field name: 'score', range -1.0 to 1.0)
    (faa.content_json ->> 'score')::numeric    AS sentiment_score,
    -- Extract human-readable summary (field name: 'summary')
    faa.content_json ->> 'summary'             AS summary_short
FROM star_public.fact_ai_analysis  faa
JOIN star_public.dim_asset         da
    ON  da.asset_sk   = faa.asset_sk
    AND da.is_current = TRUE
WHERE
    da.ticker                = 'BTC'             -- change asset here
    AND faa.analysis_type_id = 'sentiment_score'
    AND faa.generated_date  >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY faa.generated_date ASC;

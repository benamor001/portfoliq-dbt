-- ============================================================
-- portfolIQ dbt pack — Example Query 12
-- Title: Protocol Fee and Revenue Leaders — 30-Day Cumulative
-- Business context: Rank DeFi protocols by total cumulative fees and
--   revenue generated over the past 30 days. Revenue leaders are often
--   the most economically sustainable protocols. Source: DeFiLlama
--   (MIT licence data, portfolIQ-aggregated).
--   Factual on-chain derived metrics. Not financial advice.
-- Suggested BI tool: Tableau (sorted bar chart), Power BI
-- Tables: star_public.fact_protocol_economics
-- Filters: snapshot_date range last 30 days (prevents full scan)
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

SELECT
    fpe.protocol_id,
    fpe.category                            AS protocol_category,
    SUM(fpe.fees_24h_usd)                   AS total_fees_30d_usd,
    SUM(fpe.revenue_24h_usd)                AS total_revenue_30d_usd,
    AVG(fpe.fees_24h_usd)                   AS avg_daily_fees_usd,
    AVG(fpe.revenue_24h_usd)                AS avg_daily_revenue_usd,
    ROUND(
        SUM(fpe.revenue_24h_usd)::numeric
        / NULLIF(SUM(fpe.fees_24h_usd), 0),
        4
    )                                       AS revenue_to_fee_ratio,
    COUNT(DISTINCT fpe.snapshot_date)       AS data_days_available
FROM star_public.fact_protocol_economics  fpe
WHERE
    fpe.snapshot_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    fpe.protocol_id,
    fpe.category
ORDER BY total_revenue_30d_usd DESC NULLS LAST
LIMIT 10;

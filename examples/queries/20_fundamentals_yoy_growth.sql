-- ============================================================
-- portfolIQ dbt pack — Example Query 20
-- Title: Protocol Revenue YoY Growth (Year-over-Year)
-- Business context: Compare DeFi protocol revenue and fees between
--   yesterday and the same date one year ago. A positive YoY growth
--   in protocol revenue signals strengthening economic fundamentals.
--   Useful for long-term DeFi investor screens and protocol health reports.
--   Factual on-chain derived metrics. Not financial advice.
-- Suggested BI tool: Any (KPI cards, growth table)
-- Tables: star_public.fact_protocol_economics
-- Filters: snapshot_date IN (yesterday, D-365) — two point-in-time queries
-- Not financial advice. Methodology disclosed.
-- ============================================================

WITH current_period AS (
    SELECT
        protocol_id,
        category,
        fees_30d_usd            AS fees_30d_current,
        revenue_30d_usd         AS revenue_30d_current,
        fees_24h_usd            AS fees_24h_current,
        revenue_24h_usd         AS revenue_24h_current
    FROM star_public.fact_protocol_economics
    WHERE snapshot_date = CURRENT_DATE - INTERVAL '1 day'
),
prior_year AS (
    SELECT
        protocol_id,
        fees_30d_usd            AS fees_30d_prior,
        revenue_30d_usd         AS revenue_30d_prior,
        fees_24h_usd            AS fees_24h_prior,
        revenue_24h_usd         AS revenue_24h_prior
    FROM star_public.fact_protocol_economics
    WHERE snapshot_date = CURRENT_DATE - INTERVAL '365 days'
)
SELECT
    c.protocol_id,
    c.category,
    -- Current period
    ROUND(c.fees_30d_current::numeric,    2)    AS fees_30d_current_usd,
    ROUND(c.revenue_30d_current::numeric, 2)    AS revenue_30d_current_usd,
    -- Prior year
    ROUND(p.fees_30d_prior::numeric,      2)    AS fees_30d_prior_year_usd,
    ROUND(p.revenue_30d_prior::numeric,   2)    AS revenue_30d_prior_year_usd,
    -- YoY growth
    ROUND(
        100.0 * (c.fees_30d_current - p.fees_30d_prior)
        / NULLIF(p.fees_30d_prior, 0),
        2
    )                                           AS fees_yoy_growth_pct,
    ROUND(
        100.0 * (c.revenue_30d_current - p.revenue_30d_prior)
        / NULLIF(p.revenue_30d_prior, 0),
        2
    )                                           AS revenue_yoy_growth_pct
FROM current_period  c
LEFT JOIN prior_year p ON p.protocol_id = c.protocol_id
WHERE p.protocol_id IS NOT NULL  -- only protocols with 12+ months of data
ORDER BY revenue_yoy_growth_pct DESC NULLS LAST;

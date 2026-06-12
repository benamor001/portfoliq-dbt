-- ============================================================
-- portfolIQ dbt pack — Example Query 11
-- Title: News Mention Frequency by Source for a Given Asset (Last 30 Days)
-- Business context: Track how often a specific asset is mentioned per
--   editorial source over the past 30 days. A surge in mentions from
--   high-authority sources can precede price moves. Useful for media
--   monitoring and alpha signal research.
-- Suggested BI tool: Metabase (bar / table), Lightdash
-- Tables: star_public.fact_news_mention, star_public.dim_asset,
--         star_public.dim_news_source
-- Filters: asset ticker = 'BTC' + published_at last 30 days
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

-- Replace 'BTC' with any ticker available in dim_asset.
SELECT
    dns.editor                      AS source_name,
    dns.editor_normalized,
    COUNT(fnm.news_mention_sk)      AS mention_count,
    MIN(fnm.published_at)           AS first_mention,
    MAX(fnm.published_at)           AS last_mention,
    dns.article_count               AS total_articles_from_source
FROM star_public.fact_news_mention  fnm
JOIN star_public.dim_asset          da
    ON  da.asset_sk   = fnm.asset_sk
    AND da.is_current = TRUE
    AND da.ticker     = 'BTC'
LEFT JOIN star_public.dim_news_source  dns
    ON  dns.news_source_sk = fnm.news_source_sk
WHERE
    fnm.published_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY
    dns.editor,
    dns.editor_normalized,
    dns.article_count
ORDER BY mention_count DESC
LIMIT 20;

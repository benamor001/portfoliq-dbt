-- ============================================================
-- portfolIQ dbt pack — Example Query 03
-- Title: P/S Ratio Leaders — Potentially Undervalued DeFi Assets
-- Business context: Surface DeFi assets with the lowest Price-to-Sales
--   ratio at yesterday's snapshot. A low P/S signals that the market cap
--   is small relative to protocol fees generated — a classic value screen.
--   Factual valuation metric only. Not financial advice.
-- Suggested BI tool: Tableau (sorted bar chart), Metabase
-- Tables: star_public.fact_asset_fundamentals, star_public.dim_asset
-- Filters: snapshot_date = yesterday + tier IN (1, 2) + ps_ratio IS NOT NULL
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

SELECT
    da.name                     AS asset_name,
    da.ticker                   AS asset_ticker,
    da.tier                     AS tier,
    faf.ps_ratio,
    faf.pr_ratio,
    faf.fees_30d_usd            AS fees_30d_usd,
    faf.revenue_30d_usd         AS revenue_30d_usd,
    faf.fees_annualized         AS fees_annualized_usd,
    faf.methodology_version
FROM star_public.fact_asset_fundamentals  faf
JOIN star_public.dim_asset                da
    ON  da.asset_sk   = faf.asset_sk
    AND da.is_current = TRUE
WHERE
    faf.snapshot_date = CURRENT_DATE - INTERVAL '1 day'
    AND da.tier       IN (1, 2)
    AND faf.ps_ratio  IS NOT NULL
    AND faf.ps_ratio  > 0
ORDER BY faf.ps_ratio ASC
LIMIT 10;

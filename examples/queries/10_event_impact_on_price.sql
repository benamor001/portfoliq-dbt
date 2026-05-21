-- ============================================================
-- portfolIQ dbt pack — Example Query 10
-- Title: Crypto Events and Price Change in the Following 7 Days
-- Business context: For each confirmed event (halving, listing, upgrade,
--   etc.) linked to a specific asset in the past year, compute the
--   percentage price change from event date to D+1, D+3, and D+7.
--   Useful for event-driven strategy research and narrative analysis.
--   Factual event data only. Not financial advice.
-- Suggested BI tool: Tableau (narrative / event dashboard)
-- Tables: star_public.fact_event, star_public.dim_asset,
--         star_public.dim_event_type, star_public.fact_market_snapshot
-- Filters: asset ticker = 'BTC' + event_date last 365 days
-- Not financial advice. Not a fatwa. Methodology disclosed.
-- ============================================================

-- Replace 'BTC' with any ticker available in dim_asset.
WITH events_btc AS (
    SELECT
        fe.event_hk,
        fe.event_date,
        fe.event_type_id,
        fe.event_description,
        fe.event_url,
        da.name     AS asset_name,
        da.ticker   AS asset_ticker
    FROM star_public.fact_event   fe
    JOIN star_public.dim_asset    da
        ON  da.asset_sk   = fe.asset_sk
        AND da.is_current = TRUE
        AND da.ticker     = 'BTC'
    WHERE
        fe.event_date >= CURRENT_DATE - INTERVAL '365 days'
        AND fe.event_date IS NOT NULL
),
price_on_dates AS (
    SELECT
        e.event_hk,
        e.event_date,
        e.event_type_id,
        e.event_description,
        e.event_url,
        e.asset_name,
        e.asset_ticker,
        p0.price_consensus_usd                          AS price_event_day,
        p1.price_consensus_usd                          AS price_d1,
        p3.price_consensus_usd                          AS price_d3,
        p7.price_consensus_usd                          AS price_d7
    FROM events_btc e
    -- price on event day
    LEFT JOIN star_public.fact_market_snapshot  p0
        ON  p0.snapshot_date = e.event_date
        AND p0.asset_sk      = (
            SELECT asset_sk FROM star_public.dim_asset
            WHERE ticker = e.asset_ticker AND is_current = TRUE LIMIT 1
        )
    -- price D+1
    LEFT JOIN star_public.fact_market_snapshot  p1
        ON  p1.snapshot_date = e.event_date + INTERVAL '1 day'
        AND p1.asset_sk      = p0.asset_sk
    -- price D+3
    LEFT JOIN star_public.fact_market_snapshot  p3
        ON  p3.snapshot_date = e.event_date + INTERVAL '3 days'
        AND p3.asset_sk      = p0.asset_sk
    -- price D+7
    LEFT JOIN star_public.fact_market_snapshot  p7
        ON  p7.snapshot_date = e.event_date + INTERVAL '7 days'
        AND p7.asset_sk      = p0.asset_sk
)
SELECT
    event_date,
    event_type_id,
    event_description,
    event_url,
    asset_name,
    asset_ticker,
    ROUND(price_event_day::numeric, 2)  AS price_event_day_usd,
    ROUND(
        100.0 * (price_d1 - price_event_day) / NULLIF(price_event_day, 0),
        2
    )                                   AS return_d1_pct,
    ROUND(
        100.0 * (price_d3 - price_event_day) / NULLIF(price_event_day, 0),
        2
    )                                   AS return_d3_pct,
    ROUND(
        100.0 * (price_d7 - price_event_day) / NULLIF(price_event_day, 0),
        2
    )                                   AS return_d7_pct
FROM price_on_dates
ORDER BY event_date DESC;

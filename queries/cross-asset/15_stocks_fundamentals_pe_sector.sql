-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 15: P/E Ratio and EPS by GICS Sector
-- Requires: enable_stocks = true
-- Source tables: marts.fact_stock_fundamentals, marts.fact_market_price, marts.dim_asset
-- Disclaimer: Not financial advice. Methodology disclosed.
-- ============================================================

WITH latest_annual AS (
    -- Most recent 10-K per stock
    SELECT DISTINCT ON (asset_sk)
        asset_sk,
        eps_diluted,
        eps_basic,
        revenue_usd,
        net_income_usd,
        ebitda_usd,
        period_end_date,
        accession_number
    FROM marts.fact_stock_fundamentals
    WHERE filing_type = '10-K'
    ORDER BY asset_sk, period_end_date DESC
),
latest_price AS (
    SELECT DISTINCT ON (asset_sk)
        asset_sk,
        close AS close_usd,
        snapshot_date
    FROM marts.fact_market_price
    WHERE asset_kind = 'stock' AND timeframe = '1d'
    ORDER BY asset_sk, snapshot_date DESC
),
pe_calc AS (
    SELECT
        da.asset_sk,
        da.ticker,
        da.name,
        -- GICS sector stored in dim_asset.sector (populated by sat_asset_classification)
        da.gics_sector,
        da.gics_industry,
        da.listing_venue,
        lp.close_usd                                     AS price_usd,
        la.eps_diluted,
        la.eps_basic,
        la.revenue_usd,
        la.net_income_usd,
        la.ebitda_usd,
        la.period_end_date,
        -- Trailing P/E = price / EPS diluted
        CASE
            WHEN la.eps_diluted > 0
                 THEN lp.close_usd / la.eps_diluted
            ELSE NULL
        END                                              AS pe_trailing,
        -- Price-to-Sales = market cap / revenue
        CASE
            WHEN la.revenue_usd > 0
                 THEN (lp.close_usd * da.shares_outstanding_approx) / la.revenue_usd
            ELSE NULL
        END                                              AS ps_ratio,
        lp.snapshot_date
    FROM latest_annual la
    JOIN marts.dim_asset da ON da.asset_sk = la.asset_sk AND da.is_current = true
    JOIN latest_price lp ON lp.asset_sk = la.asset_sk
    WHERE da.asset_kind = 'stock'
),
sector_stats AS (
    -- Sector-level aggregates for comparison
    SELECT
        gics_sector,
        COUNT(*)                                          AS stocks_in_sector,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pe_trailing)
                                                          AS median_pe_sector,
        AVG(pe_trailing)                                  AS avg_pe_sector,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY pe_trailing)
                                                          AS p25_pe_sector,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY pe_trailing)
                                                          AS p75_pe_sector
    FROM pe_calc
    WHERE pe_trailing IS NOT NULL AND pe_trailing BETWEEN 0 AND 200  -- exclude outliers
    GROUP BY gics_sector
)
SELECT
    pc.ticker,
    pc.name,
    pc.gics_sector,
    pc.gics_industry,
    pc.listing_venue,
    ROUND(pc.price_usd::numeric, 2)            AS price_usd,
    ROUND(pc.eps_diluted::numeric, 4)          AS eps_diluted,
    ROUND(pc.pe_trailing::numeric, 2)          AS pe_trailing,
    ROUND(ss.median_pe_sector::numeric, 2)     AS median_pe_sector,
    -- Relative valuation vs sector median
    ROUND((pc.pe_trailing / NULLIF(ss.median_pe_sector, 0))::numeric, 3)
                                               AS pe_vs_sector_median,
    CASE
        WHEN pc.pe_trailing < ss.p25_pe_sector THEN 'discount_vs_sector'
        WHEN pc.pe_trailing > ss.p75_pe_sector THEN 'premium_vs_sector'
        ELSE 'in_line_vs_sector'
    END                                        AS valuation_vs_sector,
    ROUND(pc.ps_ratio::numeric, 2)             AS ps_ratio,
    pc.period_end_date                         AS filing_date,
    pc.snapshot_date                           AS price_date
FROM pe_calc pc
JOIN sector_stats ss ON ss.gics_sector = pc.gics_sector
ORDER BY pc.gics_sector, pc.pe_trailing ASC NULLS LAST;

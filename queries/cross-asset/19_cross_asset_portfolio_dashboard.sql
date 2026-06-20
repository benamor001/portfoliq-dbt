-- ============================================================
-- portfoliq-dbt v0.2.0 — Query 19: Cross-Asset Portfolio Dashboard (Fictitious)
--   5 assets: BTC (crypto) + AAPL (stock) + SPY (etf) + XAUUSD (commodity) + FEDFUNDS (macro)
--   Combines: prices + correlations + AI analysis
-- Requires: enable_stocks = true, enable_etf = true, enable_commodities = true,
--           enable_macro = true
-- Source tables: marts.fact_market_price, marts.fact_market_correlation,
--               marts.fact_macro_observation, marts.fact_ai_analysis,
--               marts.dim_asset, marts.dim_asset_kind
-- Disclaimer: Not financial advice. Methodology disclosed.
--   This is a demonstration portfolio only. Not a managed portfolio recommendation.
--   D-166 / AMF-001: no halal/compliance VERDICT is exposed by portfolIQ.
-- ============================================================

-- SECTION 1: Portfolio composition and latest prices
WITH portfolio_assets AS (
    SELECT
        da.asset_sk,
        da.ticker,
        da.name,
        da.asset_kind,
        dak.label           AS asset_kind_label,
        dak.sort_order
    FROM marts.dim_asset da
    JOIN marts.dim_asset_kind dak ON dak.asset_kind_key = da.asset_kind
    WHERE da.ticker IN ('BTC', 'AAPL', 'SPY', 'XAUUSD', 'FEDFUNDS')
      AND da.is_current = true
),
latest_prices AS (
    -- Latest price for each asset (FEDFUNDS has no price — will be NULL)
    SELECT DISTINCT ON (fmp.asset_sk)
        fmp.asset_sk,
        fmp.close           AS latest_price,
        fmp.snapshot_date,
        fmp.timeframe,
        fmp.venues_count
    FROM marts.fact_market_price fmp
    WHERE fmp.asset_sk IN (SELECT asset_sk FROM portfolio_assets)
      AND fmp.asset_kind != 'macro'  -- macro series have no OHLCV
    ORDER BY fmp.asset_sk, fmp.snapshot_date DESC
),
fedfunds_rate AS (
    -- FEDFUNDS latest value from fact_macro_observation
    SELECT fo.value AS rate, fo.observation_date
    FROM marts.fact_macro_observation fo
    JOIN portfolio_assets pa ON pa.asset_sk = fo.series_sk AND pa.ticker = 'FEDFUNDS'
    ORDER BY fo.observation_date DESC
    LIMIT 1
),
-- SECTION 2: Latest AI analysis per asset
latest_ai AS (
    SELECT DISTINCT ON (asset_sk)
        asset_sk,
        analysis_type_id,
        sentiment_label,
        sentiment_score,
        ai_summary,
        generated_at,
        prompt_version
    FROM marts.fact_ai_analysis
    WHERE analysis_type_id = 1  -- market_sentiment type
      AND asset_sk IN (SELECT asset_sk FROM portfolio_assets)
    ORDER BY asset_sk, generated_at DESC
),
-- SECTION 3: BTC correlation vs each other asset
btc_sk AS (SELECT asset_sk FROM portfolio_assets WHERE ticker = 'BTC'),
correlations AS (
    SELECT
        CASE
            WHEN fmc.asset_sk_a = btc.asset_sk THEN fmc.asset_sk_b
            ELSE fmc.asset_sk_a
        END                         AS other_asset_sk,
        fmc.pearson_30d,
        fmc.pearson_90d
    FROM marts.fact_market_correlation fmc
    CROSS JOIN btc_sk btc
    WHERE (fmc.asset_sk_a = btc.asset_sk OR fmc.asset_sk_b = btc.asset_sk)
      AND fmc.snapshot_date = (SELECT MAX(snapshot_date) FROM marts.fact_market_correlation)
      AND (fmc.asset_sk_a IN (SELECT asset_sk FROM portfolio_assets)
        OR fmc.asset_sk_b IN (SELECT asset_sk FROM portfolio_assets))
)
-- SECTION 4: Final dashboard assembly
SELECT
    pa.sort_order                                          AS display_order,
    pa.ticker,
    pa.name,
    pa.asset_kind_label,
    -- Pricing block
    ROUND(COALESCE(lp.latest_price, fr.rate)::numeric, 4) AS current_value,
    COALESCE(lp.snapshot_date, fr.observation_date)        AS value_date,
    lp.timeframe,
    lp.venues_count                                        AS consensus_venues,
    -- AI block
    ai.sentiment_label,
    ROUND(ai.sentiment_score::numeric, 3)                  AS sentiment_score,
    LEFT(ai.ai_summary, 200)                               AS ai_summary_excerpt,
    ai.generated_at                                        AS ai_generated_at,
    ai.prompt_version,
    -- Correlation vs BTC block
    ROUND(c.pearson_30d::numeric, 4)                       AS btc_corr_30d,
    ROUND(c.pearson_90d::numeric, 4)                       AS btc_corr_90d,
    -- Data lineage
    pa.asset_kind
FROM portfolio_assets pa
LEFT JOIN latest_prices lp ON lp.asset_sk = pa.asset_sk
LEFT JOIN fedfunds_rate fr ON pa.ticker = 'FEDFUNDS'
LEFT JOIN latest_ai ai ON ai.asset_sk = pa.asset_sk
LEFT JOIN correlations c ON c.other_asset_sk = pa.asset_sk
ORDER BY pa.sort_order;

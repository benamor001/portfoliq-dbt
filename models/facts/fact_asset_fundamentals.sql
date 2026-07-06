-- =============================================================================
-- portfoliq pack: fact_asset_fundamentals
-- Source : star_public.fact_asset_fundamentals
-- Grain  : (asset_sk, snapshot_date) — fundamentals per DeFi asset per day
-- Toggle : portfoliq_enable_star
--
-- P/S and P/R ratios computed from DeFiLlama (MIT) + VWAP-derived market cap.
-- Only assets with a DeFiLlama link are covered.
-- Gate: fundamentals:read (Growth tier+).
--
-- Legal  : DeFiLlama: MIT licence. Factual valuation metrics only.
--          Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    asset_sk,
    asset_id,
    snapshot_date,
    date_key,
    ps_ratio,
    pr_ratio,
    fees_30d_usd,
    revenue_30d_usd,
    fees_annualized,
    revenue_annualized,
    methodology_version

from {{ source('portfoliq', 'fact_asset_fundamentals') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

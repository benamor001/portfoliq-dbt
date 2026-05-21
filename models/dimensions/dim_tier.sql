-- =============================================================================
-- portfoliq pack: dim_tier
-- Source : star_public.dim_tier (static seed — 3 market cap tiers)
-- Grain  : tier — one row per tier level
-- Toggle : portfoliq_enable_star
--
-- Note: min_market_cap_usd_approx is indicative. Actual tier boundary is
--       market_cap_rank, NOT a fixed USD threshold.
--
-- Legal  : Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    tier,
    tier_label,
    min_rank,
    max_rank,
    min_market_cap_usd_approx

from {{ source('portfoliq', 'dim_tier') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

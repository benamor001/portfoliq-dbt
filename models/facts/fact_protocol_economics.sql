-- =============================================================================
-- portfoliq pack: fact_protocol_economics
-- Source : star_public.fact_protocol_economics
-- Grain  : (protocol_id, snapshot_date) — fees/revenue per DeFi protocol per day
-- Toggle : portfoliq_enable_star
--
-- Source: DeFiLlama (MIT licence). Named 'economics' per COMITE-010 nomenclature.
-- protocol_id = defillama_slug (direct FK — no dim_protocol in v1).
--
-- Legal  : Factual on-chain derived metrics. Not financial advice.
--          DeFiLlama: MIT licence (COMITE-008 GO). Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    protocol_id,
    date_sk,
    snapshot_date,
    fees_24h_usd,
    revenue_24h_usd,
    fees_7d_usd,
    revenue_7d_usd,
    fees_30d_usd,
    revenue_30d_usd,
    category,
    chains

from {{ source('portfoliq', 'fact_protocol_economics') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

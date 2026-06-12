-- =============================================================================
-- portfoliq pack: fact_protocol_tvl
-- Source : star_public.fact_protocol_tvl
-- Grain  : (protocol_id, snapshot_date) — TVL per DeFi protocol per day
-- Toggle : portfoliq_enable_star
--
-- tvl_usd = portfolIQ self-calculated from on-chain pool balances (VWAP-priced).
-- tvl_change_*_pct computed via LAG on portfolIQ self-calc TVL only — NOT DeFiLlama.
-- protocol_id = defillama_slug (BK from hub_defi_protocol).
--
-- Legal  : DeFiLlama cross-check fields excluded (redistribution forbidden).
--          Not financial advice. TVL self-calculated. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    protocol_id,
    snapshot_date,
    date_sk,
    tvl_usd,
    tvl_change_1d_pct,
    tvl_change_7d_pct,
    methodology_version

from {{ source('portfoliq', 'fact_protocol_tvl') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

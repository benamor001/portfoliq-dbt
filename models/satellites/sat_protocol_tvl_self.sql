-- =============================================================================
-- portfoliq pack: sat_protocol_tvl_self
-- Source : star_public.sat_protocol_tvl_self
-- Grain  : (protocol_hk, snapshot_date) — self-calculated TVL per protocol per day
-- Toggle : portfoliq_enable_star
-- Exposure: public_recomputed (Sprint 16B T-226)
--
-- R3: TVL self-calculated from on-chain pool balances.
-- DeFiLlama cross-check fields excluded (redistribution forbidden).
-- Use fact_protocol_tvl for the Star Schema grain with LAG-computed change metrics.
--
-- Legal  : tvl_defillama_check_usd and ecart_pct excluded (DeFiLlama ToS).
--          Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select *
from {{ source('portfoliq', 'sat_protocol_tvl_self') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

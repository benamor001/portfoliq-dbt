-- =============================================================================
-- portfoliq pack: dim_chain
-- Source : star_public.dim_chain (static seed — ~30 blockchain networks)
-- Grain  : chain_id — one row per blockchain
-- Toggle : portfoliq_enable_star
--
-- Note: dim_chain is seeded (static CSV). The source view passes through the
-- seed materialized in star_public by the portfolIQ internal pipeline.
--
-- Legal  : Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    chain_id,
    chain_name,
    native_symbol,
    is_evm,
    is_l2,
    parent_chain_id

from {{ source('portfoliq', 'dim_chain') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

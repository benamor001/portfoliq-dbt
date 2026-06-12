-- =============================================================================
-- portfoliq pack: dim_asset
-- Source : star_public.dim_asset (portfolIQ internal pipeline)
-- Grain  : (asset_hk, valid_from) — one row per SCD2 version of an asset
-- Toggle : portfoliq_enable_star — returns empty set when false
--
-- Legal  : coingecko_id is NEVER in this view (CoinGecko ToS §6.2).
--          Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    asset_sk,
    asset_id,
    ticker,
    name,
    tier,
    contract_address,
    sources_confirmed,
    single_source,
    methodology_version,
    valid_from,
    valid_to,
    is_current

from {{ source('portfoliq', 'dim_asset') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

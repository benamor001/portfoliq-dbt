-- =============================================================================
-- portfoliq pack: fact_market_snapshot
-- Source : star_public.fact_market_snapshot
-- Grain  : (asset_sk, snapshot_date) — one derived market snapshot per asset per day
-- Toggle : portfoliq_enable_star
--
-- price_consensus_usd = multi-exchange VWAP (3+ exchanges, MAR compliant).
-- market_cap_derived_usd = price x on-chain supply (BTC/ETH only in v1).
--
-- Legal  : Colonnes interdites : asset_hk, hashdiff, coingecko_id.
--          Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    asset_sk,
    asset_id,
    snapshot_date,
    date_key,
    price_consensus_usd,
    supply_on_chain,
    market_cap_derived_usd,
    tier_crypto,
    exchanges_count,
    methodology_version

from {{ source('portfoliq', 'fact_market_snapshot') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

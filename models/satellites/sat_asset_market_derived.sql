-- =============================================================================
-- portfoliq pack: sat_asset_market_derived
-- Source : star_public.sat_asset_market_derived
-- Grain  : (asset_hk, snapshot_date) — derived market data per asset per day
-- Toggle : portfoliq_enable_star
-- Exposure: public_recomputed (Sprint 16B T-227)
--
-- R2: market_cap_derived_usd = VWAP x on-chain supply.
-- price_consensus_usd = multi-exchange VWAP (redistributable derived data).
--
-- Legal  : price_usd / market_cap_usd (CoinGecko nominal) excluded.
--          Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select *
from {{ source('portfoliq', 'sat_asset_market_derived') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

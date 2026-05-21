-- =============================================================================
-- portfoliq pack: fact_vwap_consensus
-- Source : star_public.fact_vwap_consensus
-- Grain  : (asset_sk, snapshot_ts, timeframe) — VWAP candle per asset/time/frame
-- Toggle : portfoliq_enable_star
--
-- vwap_usd is derived portfolIQ data — redistributable (not CoinGecko nominal).
-- max_source_weight_pct <= 0.50 enforced at source (MAR compliance).
-- timeframe '1h' = Tier 1 assets only. '1d' = all tiers.
--
-- Legal  : Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    asset_sk,
    asset_id,
    snapshot_ts,
    snapshot_date,
    date_key,
    timeframe,
    vwap_usd,
    exchanges_count,
    max_source_weight_pct,
    methodology_version

from {{ source('portfoliq', 'fact_vwap_consensus') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

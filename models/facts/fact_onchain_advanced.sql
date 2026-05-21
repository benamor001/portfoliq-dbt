-- =============================================================================
-- portfoliq pack: fact_onchain_advanced
-- Source : star_public.fact_onchain_advanced
-- Grain  : (asset_sk, snapshot_date) — advanced on-chain metrics per asset per day
-- Toggle : portfoliq_enable_star
--
-- BTC-only in v1. ETH + other assets: Sprint 20+.
-- Source: bigquery-public-data.crypto_bitcoin (MIT licence).
-- Gate: onchain:read (Growth tier+).
--
-- Legal  : Not financial advice. Factual descriptive metrics. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    asset_sk,
    asset_id,
    snapshot_date,
    date_key,
    realized_cap_usd,
    mvrv_ratio,
    nupl,
    sopr,
    realized_price_usd,
    hodl_waves,
    circulating_supply_btc,
    methodology_version

from {{ source('portfoliq', 'fact_onchain_advanced') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

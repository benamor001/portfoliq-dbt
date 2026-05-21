-- =============================================================================
-- portfoliq pack: fact_onchain_core
-- Source : star_public.fact_onchain_core
-- Grain  : (asset_sk, snapshot_date) — on-chain core metrics per asset per day
-- Toggle : portfoliq_enable_star
--
-- BTC + ETH only in v1. Other assets: no data (by design, documented limitation).
-- Source: Blockstream.info (BTC) + public RPC (ETH). No Etherscan.
--
-- Legal  : Not financial advice. Factual on-chain aggregates. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    asset_sk,
    asset_id,
    snapshot_date,
    date_key,
    active_addresses,
    fees_total_usd,
    tx_count,
    avg_fee_usd,
    source_rpc

from {{ source('portfoliq', 'fact_onchain_core') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

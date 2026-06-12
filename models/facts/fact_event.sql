-- =============================================================================
-- portfoliq pack: fact_event
-- Source : star_public.fact_event
-- Grain  : (event_hk, asset_sk) — one row per event × asset pair
-- Toggle : portfoliq_enable_star
--
-- Asset-linked events only (asset_hk IS NOT NULL in source filter).
-- Market-wide events excluded (scope: BACKLOG fact_market_event).
--
-- Legal  : Not financial advice. Factual event data. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    event_fact_sk,
    event_hk,
    asset_sk,
    event_type_id,
    date_sk,
    event_date,
    event_title,
    event_description,
    event_url,
    source

from {{ source('portfoliq', 'fact_event') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

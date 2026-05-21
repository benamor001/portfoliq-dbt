-- =============================================================================
-- portfoliq pack: dim_event_type
-- Source : star_public.dim_event_type (static seed — 18 event types)
-- Grain  : event_type_id — one row per event type
-- Toggle : portfoliq_enable_star
--
-- Legal  : affects_price_typically is indicative — NOT investment advice.
--          Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    event_type_id,
    event_type_label,
    description,
    affects_price_typically

from {{ source('portfoliq', 'dim_event_type') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

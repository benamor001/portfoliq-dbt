-- =============================================================================
-- portfoliq pack: dim_analysis_type
-- Source : star_public.dim_analysis_type (static seed — 11 AI analysis types)
-- Grain  : analysis_type_id — one row per analysis type
-- Toggle : portfoliq_enable_star
--
-- Note: is_enabled=false for halal_screening and reserved_* types.
--       model_default and refresh_cadence are NULL for disabled types.
--
-- Legal  : Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    analysis_type_id,
    analysis_type_label,
    model_default,
    refresh_cadence,
    is_enabled

from {{ source('portfoliq', 'dim_analysis_type') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

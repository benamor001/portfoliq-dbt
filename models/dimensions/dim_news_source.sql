-- =============================================================================
-- portfoliq pack: dim_news_source
-- Source : star_public.dim_news_source (SCD1 — editorial source reference)
-- Grain  : news_source_id — one row per distinct news editor
-- Toggle : portfoliq_enable_star
--
-- Legal  : Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    news_source_sk,
    news_source_id,
    editor,
    editor_normalized,
    first_seen_at,
    last_seen_at,
    article_count,
    load_ts

from {{ source('portfoliq', 'dim_news_source') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

-- =============================================================================
-- portfoliq pack: sat_asset_news_public
-- Source : star_public.sat_asset_news_public
-- Grain  : article_hk — one row per news article (filtered: no title/excerpt)
-- Toggle : portfoliq_enable_star
-- Exposure: public_recomputed (Sprint 16A T-222)
--
-- R4 filtered satellite: title and excerpt excluded per CoinGecko ToS.
-- tokens_mentioned: JSONB array of asset identifiers (NER-extracted).
-- Use fact_news_mention for the exploded grain (article × asset).
--
-- Legal  : title/excerpt absent (redistribution constraint).
--          Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select *
from {{ source('portfoliq', 'sat_asset_news_public') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

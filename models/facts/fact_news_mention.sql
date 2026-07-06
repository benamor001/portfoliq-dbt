-- =============================================================================
-- portfoliq pack: fact_news_mention
-- Source : star_public.fact_news_mention
-- Grain  : (article_hk, asset_sk) — one row per article × mentioned asset
-- Toggle : portfoliq_enable_star
--
-- tokens_mentioned[] UNNESTed: 1 article mentioning 3 tokens = 3 rows.
-- Incremental in source (delete+insert on published_at window).
--
-- Legal  : coingecko_id_token excluded (CoinGecko ToS §6.2).
--          Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    news_mention_sk,
    article_hk,
    asset_sk,
    news_source_sk,
    date_sk,
    published_at

from {{ source('portfoliq', 'fact_news_mention') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

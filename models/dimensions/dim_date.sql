-- =============================================================================
-- portfoliq pack: dim_date
-- Source : star_public.dim_date (calendar dimension 2009-today+1y)
-- Grain  : one row per calendar date
-- Toggle : portfoliq_enable_star
--
-- Legal  : Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select
    date_key,
    date,
    year,
    quarter,
    month,
    month_name,
    week_of_year,
    day_of_week,
    day_name,
    day_of_month,
    day_of_year,
    is_weekend,
    is_us_market_holiday,
    fiscal_year,
    fiscal_quarter

from {{ source('portfoliq', 'dim_date') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}

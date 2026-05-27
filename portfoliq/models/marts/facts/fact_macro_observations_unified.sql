-- =============================================================================
-- dbt model: fact_macro_observations_unified  (portfoliq package)
-- layer    : marts / facts (view, schema: var('portfoliq_marts_schema'))
-- grain    : (provider, series_id, observation_date) — one row per macro datapoint
-- purpose  : Union cross-provider de toutes les séries macro pour BI consumption.
--            Permet une seule query BI sur 11 sources hétérogènes (FRED, ECB, BoJ,
--            BoK, HKMA, OECD, IMF, Eurostat, BIS, US Treasury, World Bank).
--
-- Package : portfoliq v0.1.0 — Sprint 90 Lane B extraction.
--
-- Materialization: view — la donnée est volatile (refresh quotidien), recalcul
--                  à chaque query suffit, pas de coût stockage.
--
-- LEGAL: All sources are commercial-redistribute-with-attribution.
--        See dim_data_provider + dim_data_license for attribution per source.
-- DISCLAIMER: Not financial advice. Factual macroeconomic data. Methodology disclosed.
-- =============================================================================

{{
    config(
        enabled=var('portfoliq_enable_macro', true),
        materialized='view',
        schema=var('portfoliq_marts_schema', 'marts'),
        meta={
            'exposure': 'public',
            'disclaimer': 'Not financial advice. Methodology disclosed.',
            'attribution': 'See dim_data_provider for per-source attribution requirements.'
        }
    )
}}

with fred as (
    select
        'FRED'::text                            as provider,
        series_id::text                         as series_id,
        observation_date::date                  as observation_date,
        value::numeric                          as value,
        value_unit::text                        as unit,
        frequency::text                         as frequency,
        null::text                              as country_iso3,
        record_source::text                     as record_source,
        false                                   as is_dev_dataset,
        ingested_at::timestamptz                as load_ts
    from {{ source('raw', 'fred_observations') }}
    where value is not null
),

ecb as (
    select
        'ECB'::text                             as provider,
        series_id::text                         as series_id,
        observation_date::date                  as observation_date,
        value::numeric                          as value,
        unit::text                              as unit,
        frequency::text                         as frequency,
        case
            when country_iso2 is null then 'EUR'::text
            else country_iso2::text
        end                                     as country_iso3,
        record_source::text                     as record_source,
        false                                   as is_dev_dataset,
        load_ts::timestamptz                    as load_ts
    from {{ source('dv', 'sat_macro_ecb_observation') }}
    where load_end_ts is null
),

boj as (
    select
        'BOJ'::text                             as provider,
        series_id::text                         as series_id,
        observation_date::date                  as observation_date,
        value::numeric                          as value,
        unit::text                              as unit,
        frequency::text                         as frequency,
        'JPN'::text                             as country_iso3,
        record_source::text                     as record_source,
        false                                   as is_dev_dataset,
        load_ts::timestamptz                    as load_ts
    from {{ source('dv', 'sat_macro_boj_observation') }}
    where load_end_ts is null
),

bok as (
    select
        'BOK'::text                             as provider,
        series_id::text                         as series_id,
        observation_date::date                  as observation_date,
        value::numeric                          as value,
        unit::text                              as unit,
        frequency::text                         as frequency,
        'KOR'::text                             as country_iso3,
        record_source::text                     as record_source,
        false                                   as is_dev_dataset,
        load_ts::timestamptz                    as load_ts
    from {{ source('dv', 'sat_macro_bok') }}
    where load_end_ts is null
),

hkma as (
    select
        'HKMA'::text                            as provider,
        series_id::text                         as series_id,
        observation_date::date                  as observation_date,
        value::numeric                          as value,
        unit::text                              as unit,
        frequency::text                         as frequency,
        'HKG'::text                             as country_iso3,
        record_source::text                     as record_source,
        false                                   as is_dev_dataset,
        load_ts::timestamptz                    as load_ts
    from {{ source('dv', 'sat_macro_hkma') }}
    where load_end_ts is null
),

oecd as (
    select
        'OECD'::text                                                                   as provider,
        (dataset_code || '/' || indicator_code)::text                                   as series_id,
        case
            when observation_period ~ '^[0-9]{4}-Q[1-4]$'
                then (left(observation_period,4) || '-' ||
                      (case right(observation_period,1)
                           when '1' then '01' when '2' then '04'
                           when '3' then '07' when '4' then '10' end) || '-01')::date
            when observation_period ~ '^[0-9]{4}-[0-9]{2}$'
                then (observation_period || '-01')::date
            when observation_period ~ '^[0-9]{4}$'
                then (observation_period || '-01-01')::date
            else null::date
        end                                                                             as observation_date,
        value::numeric                                                                  as value,
        unit::text                                                                      as unit,
        null::text                                                                      as frequency,
        country_iso3::text                                                              as country_iso3,
        record_source::text                                                             as record_source,
        false                                                                           as is_dev_dataset,
        load_ts::timestamptz                                                            as load_ts
    from {{ source('dv', 'sat_macro_oecd') }}
    where load_end_ts is null
),

imf as (
    select
        'IMF'::text                                                                     as provider,
        (dataset_code || '/' || indicator_code)::text                                   as series_id,
        case
            when observation_period ~ '^[0-9]{4}Q[1-4]$'
                then (left(observation_period,4) || '-' ||
                      (case right(observation_period,1)
                           when '1' then '01' when '2' then '04'
                           when '3' then '07' when '4' then '10' end) || '-01')::date
            when observation_period ~ '^[0-9]{4}$'
                then (observation_period || '-01-01')::date
            else null::date
        end                                                                             as observation_date,
        value::numeric                                                                  as value,
        unit::text                                                                      as unit,
        null::text                                                                      as frequency,
        country_iso3::text                                                              as country_iso3,
        record_source::text                                                             as record_source,
        false                                                                           as is_dev_dataset,
        load_ts::timestamptz                                                            as load_ts
    from {{ source('dv', 'sat_macro_imf') }}
    where load_end_ts is null
),

eurostat as (
    select
        'EUROSTAT'::text                                                                as provider,
        dataset_code::text                                                              as series_id,
        case
            when observation_period ~ '^[0-9]{4}-Q[1-4]$'
                then (left(observation_period,4) || '-' ||
                      (case right(observation_period,1)
                           when '1' then '01' when '2' then '04'
                           when '3' then '07' when '4' then '10' end) || '-01')::date
            when observation_period ~ '^[0-9]{4}-[0-9]{2}$'
                then (observation_period || '-01')::date
            when observation_period ~ '^[0-9]{4}$'
                then (observation_period || '-01-01')::date
            else null::date
        end                                                                             as observation_date,
        value::numeric                                                                  as value,
        unit::text                                                                      as unit,
        null::text                                                                      as frequency,
        geo_code::text                                                                  as country_iso3,
        record_source::text                                                             as record_source,
        false                                                                           as is_dev_dataset,
        load_ts::timestamptz                                                            as load_ts
    from {{ source('dv', 'sat_macro_eurostat') }}
    where load_end_ts is null
),

bis as (
    select
        'BIS'::text                                                                     as provider,
        (dataset_code || '/' || series_key)::text                                       as series_id,
        case
            when observation_period ~ '^[0-9]{4}-Q[1-4]$'
                then (left(observation_period,4) || '-' ||
                      (case right(observation_period,1)
                           when '1' then '01' when '2' then '04'
                           when '3' then '07' when '4' then '10' end) || '-01')::date
            when observation_period ~ '^[0-9]{4}$'
                then (observation_period || '-01-01')::date
            else null::date
        end                                                                             as observation_date,
        value::numeric                                                                  as value,
        unit::text                                                                      as unit,
        null::text                                                                      as frequency,
        null::text                                                                      as country_iso3,
        record_source::text                                                             as record_source,
        false                                                                           as is_dev_dataset,
        load_ts::timestamptz                                                            as load_ts
    from {{ source('dv', 'sat_macro_bis') }}
    where load_end_ts is null
),

us_treasury as (
    select
        'USTREASURY'::text                                                              as provider,
        (dataset_code || '/' || series_id)::text                                        as series_id,
        observation_date::date                                                          as observation_date,
        value::numeric                                                                  as value,
        unit::text                                                                      as unit,
        null::text                                                                      as frequency,
        'USA'::text                                                                     as country_iso3,
        record_source::text                                                             as record_source,
        false                                                                           as is_dev_dataset,
        load_ts::timestamptz                                                            as load_ts
    from {{ source('dv', 'sat_macro_us_treasury') }}
    where load_end_ts is null
),

worldbank as (
    select
        'WORLDBANK'::text                                                               as provider,
        indicator_code::text                                                            as series_id,
        (observation_year::text || '-01-01')::date                                       as observation_date,
        value::numeric                                                                  as value,
        unit::text                                                                      as unit,
        'annual'::text                                                                  as frequency,
        country_iso2::text                                                              as country_iso3,
        record_source::text                                                             as record_source,
        false                                                                           as is_dev_dataset,
        load_ts::timestamptz                                                            as load_ts
    from {{ source('dv', 'sat_macro_worldbank') }}
    where load_end_ts is null
)

select * from fred
union all select * from ecb
union all select * from boj
union all select * from bok
union all select * from hkma
union all select * from oecd
union all select * from imf
union all select * from eurostat
union all select * from bis
union all select * from us_treasury
union all select * from worldbank

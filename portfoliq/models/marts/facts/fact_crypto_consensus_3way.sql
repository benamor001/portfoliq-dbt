-- =============================================================================
-- dbt model: fact_crypto_consensus_3way  (portfoliq package)
-- layer    : marts / facts (view, schema: var('portfoliq_marts_schema'))
-- grain    : (symbol, snapshot_date) — one row per token × calendar date
-- purpose  : 3-way crypto consensus (CoinGecko + CoinPaprika + CryptoCompare).
--            Différenciateur produit clé: prix robuste à la manipulation single-source.
--
-- Package : portfoliq v0.1.0 — Sprint 90 Lane B extraction.
--
-- LEGAL: dérivée par portfolIQ — pas de redistribution de fields raw exchange.
--        Output redistribuable sous attribution (sources cités séparément).
-- DISCLAIMER: Not financial advice. Methodology disclosed.
-- =============================================================================

{{
    config(
        enabled=var('portfoliq_enable_crypto', true),
        materialized='view',
        schema=var('portfoliq_marts_schema', 'marts'),
        meta={
            'exposure': 'public_recomputed',
            'ai_generated': false,
            'disclaimer': 'Not financial advice. Methodology disclosed.',
            'attribution': 'Derived 3-way consensus by portfolIQ. Sources: CoinGecko + CoinPaprika + CryptoCompare.'
        }
    )
}}

with coingecko as (
    select
        upper(trim(symbol))                                          as symbol_upper,
        (load_ts::timestamptz at time zone 'UTC')::date              as snapshot_date,
        current_price_usd::numeric                                   as price_usd
    from {{ source('dv', 'stg_coingecko_market') }}
    where current_price_usd is not null
      and symbol is not null
      and trim(symbol) != ''
),

paprika as (
    select
        upper(split_part(paprika_id, '-', 1))   as symbol_upper,
        snapshot_date::date                     as snapshot_date,
        price_usd::numeric                      as price_usd
    from {{ source('dv', 'sat_crypto_paprika_snapshot') }}
    where load_end_ts is null
      and price_usd is not null
      and paprika_id is not null
),

cryptocompare as (
    select
        upper(trim(symbol))                     as symbol_upper,
        snapshot_date::date                     as snapshot_date,
        price_usd::numeric                      as price_usd
    from {{ source('dv', 'sat_crypto_cryptocompare_snapshot') }}
    where load_end_ts is null
      and price_usd is not null
      and symbol is not null
),

coingecko_dedup as (
    select symbol_upper, snapshot_date, avg(price_usd) as price_usd
    from coingecko
    group by symbol_upper, snapshot_date
),
paprika_dedup as (
    select symbol_upper, snapshot_date, avg(price_usd) as price_usd
    from paprika
    group by symbol_upper, snapshot_date
),
cryptocompare_dedup as (
    select symbol_upper, snapshot_date, avg(price_usd) as price_usd
    from cryptocompare
    group by symbol_upper, snapshot_date
),

joined as (
    select
        coalesce(c.symbol_upper, p.symbol_upper, cc.symbol_upper)    as symbol,
        coalesce(c.snapshot_date, p.snapshot_date, cc.snapshot_date) as snapshot_date,
        c.price_usd  as price_coingecko,
        p.price_usd  as price_paprika,
        cc.price_usd as price_cryptocompare
    from coingecko_dedup c
    full outer join paprika_dedup p
        on c.symbol_upper = p.symbol_upper
       and c.snapshot_date = p.snapshot_date
    full outer join cryptocompare_dedup cc
        on coalesce(c.symbol_upper, p.symbol_upper) = cc.symbol_upper
       and coalesce(c.snapshot_date, p.snapshot_date) = cc.snapshot_date
),

prices_array as (
    select
        symbol,
        snapshot_date,
        price_coingecko,
        price_paprika,
        price_cryptocompare,
        array_remove(
            array[price_coingecko, price_paprika, price_cryptocompare]::numeric[],
            null
        ) as prices
    from joined
    where symbol is not null
      and snapshot_date is not null
)

select
    symbol,
    snapshot_date,
    price_coingecko,
    price_paprika,
    price_cryptocompare,
    cardinality(prices)                                              as sources_count,
    case
        when cardinality(prices) > 0
            then (select avg(p) from unnest(prices) as p)
        else null
    end                                                              as consensus_price_usd,
    case
        when cardinality(prices) >= 2
            then (select stddev_samp(p) from unnest(prices) as p)
        else null
    end                                                              as std_deviation,
    case
        when cardinality(prices) >= 2
             and (select avg(p) from unnest(prices) as p) > 0
            then abs(
                    (select max(p) from unnest(prices) as p)
                    - (select min(p) from unnest(prices) as p)
                 )
                 / nullif((select avg(p) from unnest(prices) as p), 0)
        else null
    end                                                              as max_deviation_pct,
    (cardinality(prices) >= 2)                                       as is_robust_consensus
from prices_array

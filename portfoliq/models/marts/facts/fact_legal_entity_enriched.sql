-- =============================================================================
-- dbt model: fact_legal_entity_enriched  (portfoliq package)
-- layer    : marts / facts (view, schema: var('portfoliq_marts_schema'))
-- grain    : asset_hk — one row per asset with all available identifier crosswalks
-- purpose  : Cross-reference view LEI + ISIN + CUSIP + SEDOL + WKN + FIGI +
--            bbg_ticker + SIREN + Companies House Number.
--            Permet lookup unique d'un asset par n'importe quel identifier.
--
-- Package : portfoliq v0.1.0 — Sprint 90 Lane B extraction.
--
-- LEGAL: GLEIF=CC0, OpenFIGI=open identifiers, SIRENE=Etalab v2, Companies House=OGL v3.
--        All redistributable with attribution. See dim_data_provider.
-- DISCLAIMER: Not financial advice. Methodology disclosed.
-- =============================================================================

{{
    config(
        enabled=var('portfoliq_enable_legal_entity', true),
        materialized='view',
        schema=var('portfoliq_marts_schema', 'marts'),
        meta={
            'exposure': 'public',
            'ai_generated': false,
            'disclaimer': 'Not financial advice. Methodology disclosed.',
            'attribution': 'Identifiers from GLEIF (CC0), OpenFIGI, INSEE SIRENE, UK Companies House.'
        }
    )
}}

with assets as (
    select
        asset_hk,
        identifier,
        asset_kind
    from {{ source('dv', 'hub_asset') }}
),

figi_active as (
    select
        asset_hk,
        figi,
        composite_figi,
        share_class_figi,
        bbg_ticker,
        exchange_code            as figi_exchange_code,
        market_sector            as figi_market_sector,
        security_type            as figi_security_type,
        isin                     as figi_isin,
        cusip                    as figi_cusip,
        sedol                    as figi_sedol,
        wkn                      as figi_wkn
    from {{ source('dv', 'sat_asset_figi') }}
    where load_end_ts is null
),

sirene_active as (
    select
        asset_hk,
        siren,
        siret_siege,
        denomination_unite_legale  as sirene_legal_name,
        categorie_juridique        as sirene_legal_form_code,
        activite_principale_naf    as sirene_naf_code
    from {{ source('dv', 'sat_asset_sirene') }}
    where load_end_ts is null
),

companies_house_active as (
    select
        asset_hk,
        company_number             as uk_company_number,
        company_name               as uk_company_name,
        company_type               as uk_company_type,
        company_status             as uk_company_status,
        sic_codes                  as uk_sic_codes
    from {{ source('dv', 'sat_asset_companies_house') }}
    where load_end_ts is null
),

link_pref as (
    select
        asset_hk,
        legal_entity_hk,
        relationship_type,
        row_number() over (
            partition by asset_hk
            order by case when lower(relationship_type) = 'issuer' then 0 else 1 end,
                     load_ts desc
        ) as rn
    from {{ source('dv', 'link_asset_legal_entity') }}
),
link_active as (
    select asset_hk, legal_entity_hk, relationship_type
    from link_pref
    where rn = 1
),

hub_le as (
    select
        legal_entity_hk,
        lei
    from {{ source('dv', 'hub_legal_entity') }}
),

sat_le_active as (
    select
        legal_entity_hk,
        legal_name,
        legal_jurisdiction,
        legal_form_code,
        entity_status,
        ultimate_parent_lei,
        direct_parent_lei
    from {{ source('dv', 'sat_legal_entity') }}
    where load_end_ts is null
)

select
    a.asset_hk,
    a.identifier,
    a.asset_kind,

    -- LEI (GLEIF)
    hl.lei,
    le.legal_name                       as lei_legal_name,
    le.legal_jurisdiction               as lei_jurisdiction,
    le.legal_form_code                  as lei_legal_form_code,
    le.entity_status                    as lei_entity_status,
    le.ultimate_parent_lei,
    le.direct_parent_lei,
    lk.relationship_type                as lei_relationship_type,

    -- Bloomberg FIGI family
    f.figi,
    f.composite_figi,
    f.share_class_figi,
    f.bbg_ticker,
    f.figi_exchange_code,
    f.figi_market_sector,
    f.figi_security_type,

    -- Cross-reference identifiers
    f.figi_isin                         as isin,
    f.figi_cusip                        as cusip,
    f.figi_sedol                        as sedol,
    f.figi_wkn                          as wkn,

    -- French SIRENE
    s.siren,
    s.siret_siege,
    s.sirene_legal_name,
    s.sirene_legal_form_code,
    s.sirene_naf_code,

    -- UK Companies House
    ch.uk_company_number,
    ch.uk_company_name,
    ch.uk_company_type,
    ch.uk_company_status,
    ch.uk_sic_codes,

    -- Identifier completeness signal (0..8)
    (
        (hl.lei is not null)::int
      + (f.figi is not null)::int
      + (f.figi_isin is not null)::int
      + (f.figi_cusip is not null)::int
      + (f.figi_sedol is not null)::int
      + (f.figi_wkn is not null)::int
      + (s.siren is not null)::int
      + (ch.uk_company_number is not null)::int
    ) as identifier_count

from assets a
left join figi_active             f  on f.asset_hk  = a.asset_hk
left join sirene_active           s  on s.asset_hk  = a.asset_hk
left join companies_house_active  ch on ch.asset_hk = a.asset_hk
left join link_active             lk on lk.asset_hk = a.asset_hk
left join hub_le                  hl on hl.legal_entity_hk = lk.legal_entity_hk
left join sat_le_active           le on le.legal_entity_hk = lk.legal_entity_hk

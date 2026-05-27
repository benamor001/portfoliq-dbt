# portfoliq-dbt

> portfolIQ marts as a dbt package. Five battle-tested BI-ready models on top of
> the portfolIQ Data Vault layer, packaged so you can `dbt deps` them straight
> into your project.
>
> **Not financial advice. Not a fatwa. Methodology disclosed.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![dbt](https://img.shields.io/badge/dbt-%3E%3D1.7-orange)](https://docs.getdbt.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org)
[![Version](https://img.shields.io/badge/version-0.1.0-green)](#)

---

## What's in the box

| Model                                | Type | Grain                              | Purpose                                                       |
| ------------------------------------ | ---- | ---------------------------------- | ------------------------------------------------------------- |
| `fact_macro_observations_unified`    | view | (provider, series_id, obs_date)    | Single union view across 11 macro providers (FRED, ECB, BoJ, BoK, HKMA, OECD, IMF, Eurostat, BIS, US Treasury, World Bank). |
| `fact_crypto_consensus_3way`         | view | (symbol, snapshot_date)            | Daily 3-way crypto consensus price (CoinGecko + CoinPaprika + CryptoCompare). Robustness against single-source manipulation. |
| `fact_legal_entity_enriched`         | view | asset_hk                           | Identifier crosswalk: LEI + FIGI + ISIN + CUSIP + SEDOL + WKN + SIREN + UK Companies House. |
| `dim_data_provider`                  | seed | provider_code                      | Catalog of data providers with attribution + redistribution constraints. |
| `dim_data_license`                   | seed | license_code                       | Catalog of data licenses (CC0, CC-BY, OGL v3, Etalab v2, etc.). |

All models live in the schema given by `var('portfoliq_marts_schema')` (default `marts`).
All upstream Data Vault objects are read from `var('portfoliq_dv_schema')` (default `dv`).

---

## Quickstart

### 1. Add to `packages.yml`

```yaml
packages:
  - git: "https://github.com/benamor001/portfoliq-dbt.git"
    revision: v0.1.0
```

Then `dbt deps`.

### 2. (Optional) Override schemas in your `dbt_project.yml`

The package defaults assume your portfolIQ replica uses `dv` for the Data Vault
schema and materializes marts into `marts`. Override if your DB uses different
names:

```yaml
vars:
  portfoliq_dv_schema: 'piq_dv'          # default 'dv'
  portfoliq_marts_schema: 'piq_marts'    # default 'marts'

  # Optional — disable a fact family if you don't ingest those satellites
  portfoliq_enable_macro: true
  portfoliq_enable_crypto: true
  portfoliq_enable_legal_entity: true
```

### 3. Seed + run

```bash
dbt seed --select portfoliq
dbt run  --select portfoliq
dbt test --select portfoliq    # warn-only by default — see Testing below
```

---

## Prerequisites

You must have the upstream portfolIQ Data Vault objects materialized in your
target database. Either:

- **Option A — Replica.** Subscribe to the portfolIQ Postgres read replica (Growth
  plan or above) and point this package at the replicated schema.
- **Option B — Self-host.** Clone `finance-data-api`, run its full dbt project
  to produce the `dv.*` tables locally, then install this package against that.

Concretely, this package reads from:

```
{{ var('portfoliq_dv_schema') }}.hub_asset
{{ var('portfoliq_dv_schema') }}.hub_legal_entity
{{ var('portfoliq_dv_schema') }}.link_asset_legal_entity
{{ var('portfoliq_dv_schema') }}.sat_asset_figi
{{ var('portfoliq_dv_schema') }}.sat_asset_sirene
{{ var('portfoliq_dv_schema') }}.sat_asset_companies_house
{{ var('portfoliq_dv_schema') }}.sat_legal_entity
{{ var('portfoliq_dv_schema') }}.sat_crypto_paprika_snapshot
{{ var('portfoliq_dv_schema') }}.sat_crypto_cryptocompare_snapshot
{{ var('portfoliq_dv_schema') }}.stg_coingecko_market
{{ var('portfoliq_dv_schema') }}.sat_macro_ecb_observation
{{ var('portfoliq_dv_schema') }}.sat_macro_boj_observation
{{ var('portfoliq_dv_schema') }}.sat_macro_bok
{{ var('portfoliq_dv_schema') }}.sat_macro_hkma
{{ var('portfoliq_dv_schema') }}.sat_macro_oecd
{{ var('portfoliq_dv_schema') }}.sat_macro_imf
{{ var('portfoliq_dv_schema') }}.sat_macro_eurostat
{{ var('portfoliq_dv_schema') }}.sat_macro_bis
{{ var('portfoliq_dv_schema') }}.sat_macro_us_treasury
{{ var('portfoliq_dv_schema') }}.sat_macro_worldbank
raw.fred_observations
```

If your DB doesn't have all of them, set the relevant
`portfoliq_enable_macro / _crypto / _legal_entity` var to `false` to skip those
fact models.

---

## Example queries

### Macro: latest CPI across providers

```sql
select
    provider,
    series_id,
    observation_date,
    value,
    unit
from {{ ref('fact_macro_observations_unified') }}
where series_id ilike '%cpi%'
  and observation_date >= current_date - interval '12 month'
order by observation_date desc, provider;
```

### Crypto: today's robust consensus prices

```sql
select
    symbol,
    consensus_price_usd,
    sources_count,
    max_deviation_pct
from {{ ref('fact_crypto_consensus_3way') }}
where snapshot_date = current_date
  and is_robust_consensus = true
order by sources_count desc, max_deviation_pct asc nulls last;
```

### Entity resolution: find an asset by any identifier

```sql
select
    asset_hk,
    identifier,
    asset_kind,
    lei, lei_legal_name,
    figi, isin, cusip, sedol,
    siren, uk_company_number,
    identifier_count
from {{ ref('fact_legal_entity_enriched') }}
where isin = 'FR0000131104'                  -- BNP Paribas
   or cusip = '037833100'                    -- Apple
   or siren = '662042449'                    -- Total
order by identifier_count desc;
```

### Attribution: surface provider compliance text

```sql
select distinct
    f.provider,
    p.attribution_text,
    l.license_name,
    l.license_url
from {{ ref('fact_macro_observations_unified') }} f
join {{ ref('dim_data_provider') }} p using (provider_code)
join {{ ref('dim_data_license') }}  l using (license_code)
where p.is_active = true;
```

---

## Testing

By default this package's tests run with **`severity: warn`** so they never
break the host project's CI on first install. Tests cover:

- Composite grain uniqueness (`provider+series_id+obs_date`, `symbol+snapshot_date`)
- `not_null` on every critical identifier
- `accepted_values` on enums (provider codes, asset_kind, sources_count)
- `relationships` from facts to dimension seeds
- Anti-orphan join: `fact_legal_entity_enriched.asset_hk` → `dv.hub_asset.asset_hk`

To enforce errors instead of warnings in your own project:

```yaml
# your dbt_project.yml
tests:
  portfoliq:
    +severity: error
```

---

## Versioning + Roadmap

Semantic versioning. Current line is `0.x` — **may break minor** until the
schema stabilises with the Star Schema commercialisation track (portfolIQ
Sprint 18-21). Pin a specific tag in `packages.yml` (`revision: v0.1.0`) for
production safety.

Roadmap:

- `0.2.0` — add `fact_market_price` polymorphic OHLCV (in progress in main project)
- `0.3.0` — add `dim_asset` conformed dimension
- `1.0.0` — schema freeze, dbt Hub submission

See [CHANGELOG.md](CHANGELOG.md).

---

## Legal & data licensing

This dbt **package** is MIT-licensed (see [LICENSE](LICENSE)).

The **upstream data** ingested by the parent project is governed by each
provider's license — surfaced through the `dim_data_license` and
`dim_data_provider` seeds. Notable upstreams:

| Provider                | License            | Redistribution        |
| ----------------------- | ------------------ | --------------------- |
| FRED                    | Public domain      | Yes, with attribution |
| ECB SDW                 | ECB Open Access    | Yes, with attribution |
| GLEIF (LEI)             | CC0                | Yes, no attribution   |
| OpenFIGI                | OpenFIGI Open      | Yes                   |
| INSEE SIRENE            | Etalab v2          | Yes, with attribution |
| UK Companies House      | OGL v3             | Yes, with attribution |
| CoinGecko / Paprika / CryptoCompare | Per-ToS  | Derived only (we redistribute consensus, not raw) |

Always join your downstream queries against `dim_data_provider.attribution_text`
to display the right credit line.

**Disclaimer.** Not financial advice. Not a fatwa. Methodology disclosed.

---

## Support

Issues / questions: open a GitHub issue on the package repo
(`github.com/benamor001/portfoliq-dbt`).

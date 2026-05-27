{% docs __overview__ %}

# portfoliq-dbt

> portfolIQ marts as a dbt package — 3 facts + 2 dimensions exposing the
> portfolIQ Data Vault to your BI / analytics workspace.

## What you get

Five models, all in the `marts` schema (configurable):

- **`fact_macro_observations_unified`** — single view union over 11 macro
  providers (FRED, ECB, BoJ, BoK, HKMA, OECD, IMF, Eurostat, BIS, US Treasury,
  World Bank). One BI query, all macro.
- **`fact_crypto_consensus_3way`** — daily 3-way crypto consensus price
  (CoinGecko + CoinPaprika + CryptoCompare). Robustness signal against
  single-source manipulation: `is_robust_consensus = true` ⇔ ≥2 providers agree.
- **`fact_legal_entity_enriched`** — entity resolution across LEI, FIGI, ISIN,
  CUSIP, SEDOL, WKN, SIREN, UK Companies House. `identifier_count` ranks how
  well-mapped an asset is.
- **`dim_data_provider`** — provider catalog with attribution + redistribution
  metadata. Join `fact.provider = dim_data_provider.provider_code`.
- **`dim_data_license`** — license catalog. Chain through
  `dim_data_provider.license_code` to filter redistributable vs non-commercial
  subsets.

## Configuration

| Variable                          | Default  | Purpose                                          |
| --------------------------------- | -------- | ------------------------------------------------ |
| `portfoliq_dv_schema`             | `dv`     | Upstream Data Vault schema in your DB            |
| `portfoliq_marts_schema`          | `marts`  | Target schema for this package's outputs         |
| `portfoliq_enable_macro`          | `true`   | Materialize `fact_macro_observations_unified`    |
| `portfoliq_enable_crypto`         | `true`   | Materialize `fact_crypto_consensus_3way`         |
| `portfoliq_enable_legal_entity`   | `true`   | Materialize `fact_legal_entity_enriched`         |

## Legal

This package is MIT-licensed. Upstream data is governed by each provider's
license — see `dim_data_license` for the catalog. Always surface
`dim_data_provider.attribution_text` when displaying derived data.

Not financial advice. Not a fatwa. Methodology disclosed.

{% enddocs %}

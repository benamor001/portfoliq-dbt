# Changelog

All notable changes to portfoliq-dbt are documented here.
Format: [Semantic Versioning](https://semver.org/).

---

## [0.1.0] — 2026-05-27 (unreleased)

Initial extraction from `finance-data-api` Sprint 89 Lane B marts.

### Added

**Fact models (3)**
- `fact_macro_observations_unified` — single union view across 11 macro
  providers (FRED, ECB, BoJ, BoK, HKMA, OECD, IMF, Eurostat, BIS, US Treasury,
  World Bank). Normalizes heterogeneous `observation_period` formats to
  `DATE = first day of period`. Materialization: view.
- `fact_crypto_consensus_3way` — 3-way daily crypto consensus price (CoinGecko +
  CoinPaprika + CryptoCompare). Exposes consensus AVG, std-deviation, max
  deviation %, and `is_robust_consensus` flag. Materialization: view.
- `fact_legal_entity_enriched` — entity resolution crosswalk over LEI (GLEIF),
  FIGI/ISIN/CUSIP/SEDOL/WKN (OpenFIGI), SIREN (INSEE), UK Companies House.
  Surfaces `identifier_count` (0..8) as a coverage signal. Materialization: view.

**Seed dimensions (2)**
- `dim_data_provider` — catalog of macro/identifier/crypto providers with
  category, license FK, attribution + redistribution constraints. PK
  `provider_code`.
- `dim_data_license` — license catalog (CC0, CC-BY, OGL v3, Etalab v2, ECB
  Open Access, etc.). PK `license_code`.

**Configuration**
- `portfoliq_dv_schema` (default `dv`) — upstream Data Vault schema override.
- `portfoliq_marts_schema` (default `marts`) — target schema for facts + dims.
- `portfoliq_enable_macro / _crypto / _legal_entity` — per-family toggles
  (all `true` by default).

**Tests**
- `dbt_utils.unique_combination_of_columns` on both composite-grain facts.
- `not_null` + `accepted_values` + `relationships` on all critical columns.
- Default `+severity: warn` so the package never breaks a host project's CI on
  first install (override to `error` in your own `dbt_project.yml`).

**Documentation**
- README.md with quickstart, example queries, and legal notes.
- LICENSE — MIT.
- docs/overview.md — dbt-rendered overview doc.

### Dependencies
- `dbt-labs/dbt_utils >= 1.1.0, < 2.0.0`

### Requires
- dbt-core >= 1.7.0
- PostgreSQL 16 (TimescaleDB optional; no hypertable-specific features used in
  this package).

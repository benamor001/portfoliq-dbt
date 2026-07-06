# NOTICE — portfoliq-dbt package

Version 0.2.0 — Copyright (c) 2026 portfolIQ (portfoliq.io)

This file fulfills the disclosure obligations defined in §9quinquies.7 of the
portfolIQ legal validation (legal/SOURCES-M0-validation.md, COMITE-010).
Seven clauses are mandatory per condition §9quinquies.9.8.

---

## Clause A — License grant (ELv2)

The portfoliq-dbt package is distributed under the **Elastic License v2 (ELv2)**.
See `LICENSE` for the full text.

Key restriction under ELv2: **you may not provide the Software to third parties
as a hosted or managed service** where the service provides users access to a
substantial set of the features or functionality of this package. In other words:
you may not operate a competing "dbt-transformation-as-a-service" or
"Data-as-a-Service" built primarily on this package.

portfolIQ grants each active subscriber a non-exclusive, non-transferable,
non-sublicensable license to use the portfoliq-dbt package for **internal data
transformation purposes** within the subscriber's organization, for the duration
of an active portfolIQ subscription. Upon termination of the subscription, the
subscriber must cease active use; already-materialized metrics may be retained
for historical reference.

---

## Clause B — No data included — Attribution of upstream sources

The portfoliq-dbt package contains **transformation code only**. It does not
contain, bundle, or redistribute any market data.

The subscriber is responsible for ingesting source data into a `raw.*` schema
in compliance with the terms of each upstream provider. portfolIQ does not
grant any sub-license to those sources. The following sources are referenced
by the transformation models:

| Source | License / Terms | Usage in models |
|--------|----------------|-----------------|
| CoinGecko Demo API | CoinGecko ToS — free tier, no redistribution of raw data | Token metadata, market cap, OHLCV |
| DeFiLlama | MIT License (open-source) | Protocol TVL data |
| Federal Reserve (FRED) | Public domain (U.S. government) | Macro indicators |
| ECB Statistical Data Warehouse (SDW) | ECB open data terms | EUR exchange rates, monetary data |
| BigQuery Public Datasets (crypto_ethereum, etc.) | Google Public Data terms (CC0 / Apache 2.0 per dataset) | On-chain reference data |

The subscriber must verify the current terms of each source at the time of use.
portfolIQ's validation snapshot is dated 2026-05-20 (COMITE-010).

Attribution per source terms:
- CoinGecko: "Powered by CoinGecko API" where user-visible output is derived from CoinGecko fields.
- DeFiLlama: acknowledgment recommended in derived products per project norms.
- FRED: "Source: Federal Reserve Bank of St. Louis" per FRED usage guidelines.
- ECB: "Source: European Central Bank" per ECB open data policy.

---

## Clause C — Internal-only models — No public re-exposure

Models tagged `meta.exposure: internal_only` in `models/schema.yml` **must not**
be exposed publicly by the subscriber (e.g. via the subscriber's own public API,
marketplace listing, or data product).

This restriction reflects the upstream source terms from which these models derive
and is a condition of the ELv2 license grant. Only models tagged
`meta.exposure: public` may be surfaced in subscriber-facing products.

Note: portfoliq-dbt v0.1.0 contains zero `internal_only` models. The DV2 layer
(hubs, links, satellites raw) is intentionally excluded from this distribution
and remains internal to portfolIQ. Any future model added with
`meta.exposure: internal_only` must be removed from the package or its exposure
changed before release.

---

## Clause D — No competing data product

The subscriber may not use the portfoliq-dbt package to build a data product
that is substantially similar to portfolIQ's published API and offered as a
competing service. Internal use, derived analytics, and client-specific
applications are permitted.

Specifically, the subscriber may not:
- Re-syndicate, re-sell, sub-license, or redistribute portfolIQ API responses
  (in whole or in substantial part) as a standalone data feed.
- Bulk-export portfolIQ data to populate a third-party data catalog,
  marketplace listing, or competing API.
- Train machine learning models on portfolIQ API output for the purpose of
  building a competing data product (training for own internal applications
  is permitted).

---

## Clause E — No financial advice — Disclaimer

**portfolIQ does not provide investment advice or personalized
recommendations.**

The metrics computed by this package are factual market data and
methodology-disclosed derived indicators. They are provided **for informational
purposes only** and do not constitute financial advice, investment
recommendations, or regulatory benchmarks under Regulation (EU) 2016/1011 (BMR).

> "Not financial advice. Methodology disclosed."

Subscribers are solely responsible for their own investment decisions and for
communicating appropriate disclaimers to their own users.

---

## Clause F — AI-generated content

Certain columns in the output schemas are tagged `ai_generated: true`
(see `meta.ai_generated: true` in `models/schema.yml`).

These columns contain content generated by large language models (Claude Haiku /
Claude Sonnet, Anthropic). AI-generated content:
- Is not verified by a qualified financial analyst or Islamic finance scholar.
- May contain hallucinations or errors.
- Carries the same "not financial advice" disclaimer as all other
  portfolIQ outputs.
- Is historized with a `prompt_version` and `generated_at` timestamp so that
  changes in AI-generated interpretations are traceable.

Subscribers must communicate to their own users that certain data fields are
AI-generated when those fields are surfaced in user-facing products.

---

## Clause G — RGPD / GDPR — No PII in package

The portfoliq-dbt package is **code only**. It contains zero personally
identifiable information (PII).

The seeds bundled with the package (`seeds/`) contain only reference data
(chain names, event type labels, tier thresholds, analysis type labels) with
no personal data.

When the subscriber connects this package to their own data sources that may
contain personal data, **the subscriber is the data controller** and is solely
responsible for their own GDPR compliance, including lawful basis for processing,
data subject rights, and retention policies.

portfolIQ's infrastructure (when the subscriber uses the portfolIQ API as a
source) is hosted in the EU (Hetzner DE/FI) and complies with GDPR as a data
processor. A Data Processing Agreement (DPA) is available for B2B subscribers
on request at privacy@portfoliq.io.

---

---

## Clause H — v0.2.0 Multi-Asset Source Extension

The following sources are added in portfoliq-dbt v0.2.0. Each column indicates whether
portfolIQ redistributes the raw data or derived/transformed outputs only.

This section fulfills the disclosure obligation of §9quinquies.7 for the v0.2.0 release
(COMITE-010 extension, 2026-05-22).

| Source | License / Terms | Redistribuable (raw) | Redistribuable (dérivé) | Usage dans le pack | Référence légale |
|--------|----------------|----------------------|-------------------------|--------------------|-----------------|
| FRED — Federal Reserve Bank of St. Louis | Public domain (U.S. government work) | Yes | Yes | `sat_macro_observation`, `sat_commodity_spot`, `fact_macro_observation` — macro series, commodity spots (WTI, Gold, Silver, etc.) | 12 U.S.C. § 225a; FRED usage guidelines (no attribution required, encouraged: "Source: FRED, Federal Reserve Bank of St. Louis") |
| ECB Statistical Data Warehouse (SDW) | ECB open data terms | Yes | Yes | `stg_ecb_sdw_observations`, `sat_fx_rate`, `fact_macro_observation` — EUR pairs, monetary policy rates, Eurozone macro | ECB open data policy: free reuse with attribution "Source: European Central Bank" |
| SEC EDGAR — U.S. Securities and Exchange Commission | Public domain (17 CFR §200.80) | Yes | Yes | `stg_sec_edgar_xbrl`, `sat_stock_fundamentals`, `fact_stock_fundamentals` — XBRL GAAP fundamentals; `stg_sec_edgar_13f`, `sat_etf_holdings` — 13F/N-PORT institutional holdings | 17 CFR §200.80 — SEC data is U.S. government work, no copyright. EDGAR API ToS (2024): free, bulk download permitted for non-real-time use. Attribution: "Source: SEC EDGAR" |
| Tiingo / Polygon / FMP (stock OHLCV) | Tiingo ToS: internal use only — redistribution of raw data forbidden | **No** (raw) | **Yes** (dérivé) | `stg_tiingo_stock_eod` → `sat_stock_ohlcv` (`internal_only`, not exposed in pack) → `sat_stock_market_derived` (VWAP + derived metrics, `public_recomputed`, redistribuable). Raw data is NEVER exposed in this pack. | Tiingo ToS §4 "You may not resell or redistribute the data." The pack distributes only VWAP-derived aggregates computed by portfolIQ. Subscriber must verify their own Tiingo license for raw ingestion. |
| KIDs PRIIPs — EU UCITS Key Information Documents | EU public regulatory documents (UCITS IV Directive 2009/65/EC; PRIIPs Reg. EU 1286/2014) | Yes | Yes | `stg_kid_priips`, `sat_etf_holdings` — EU ETF holdings from regulatory KIDs (publicly filed and mandated for investor access) | EU regulations require public accessibility of KIDs. Commercial use of structured data extracted from KIDs is permitted (documents are public by law). Attribution: "Source: [Fund Manager] KIDs PRIIPs filing" where applicable. |
| EDINET — Japan FSA Electronic Disclosure for Investors | PDL 1.0 (Public Domain Licence 1.0 Japan — Government) | Yes | Yes | `sat_stock_fundamentals` (Japan-listed companies) — XBRL financial filings | EDINET PDL 1.0: reuse including commercial use permitted with attribution "Source: EDINET (Japan FSA)". XBRL data may be extracted and redistributed with attribution. |
| TWSE — Taiwan Stock Exchange | Open Government License v1.0 (Taiwan National Development Council) | Yes | Yes | `sat_stock_fundamentals` (Taiwan-listed companies) — TWSE financial statements | OGL Taiwan v1.0: commercial use permitted with attribution "Source: Taiwan Stock Exchange Corporation (TWSE)". Subscriber must not imply TWSE endorsement. |

### Subscriber obligations for v0.2.0 sources

1. **FRED** — Attribution encouraged: "Source: FRED, Federal Reserve Bank of St. Louis."
2. **ECB SDW** — Attribution required: "Source: European Central Bank."
3. **SEC EDGAR** — Attribution recommended: "Source: SEC EDGAR." Accession number (`accession_number` column) must be preserved for audit trail per MAR/BMR.
4. **Tiingo et al.** — Subscribers must hold their own valid Tiingo/Polygon/FMP license to ingest raw `raw.tiingo_stock_eod_*` data. portfolIQ's derived models (`sat_stock_market_derived`) do not transfer any Tiingo license to the subscriber.
5. **KIDs PRIIPs** — Attribution per fund manager where applicable. Structural accuracy of KIDs data is the fund manager's responsibility.
6. **EDINET** — Attribution: "Source: EDINET (Japan FSA)." Must not imply FSA endorsement.
7. **TWSE** — Attribution: "Source: Taiwan Stock Exchange Corporation (TWSE)." Must not imply TWSE endorsement.

portfolIQ's legal validation snapshot for v0.2.0 sources is dated 2026-05-22 (COMITE-010 extension).
Subscribers must verify current terms at time of use. Terms may change.

---

## References

- Full legal validation: `legal/SOURCES-M0-validation.md` §9quinquies (COMITE-010, 2026-05-20; v0.2.0 extension 2026-05-22)
- Package license: `LICENSE` (ELv2)
- Package readme: `README.md`
- Contributing guide: `CONTRIBUTING.md`
- Publishing procedure: `PUBLISHING.md`
- Changelog: `CHANGELOG.md`

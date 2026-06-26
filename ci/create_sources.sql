-- CI-only : crée les 6 tables sources star_public.* (VIDES) que les modèles du
-- package lisent via source('portfoliq', X). Permet au full-build matrix de tourner
-- sur une DB neuve (postgres + duckdb) sans la vraie donnée portfolIQ.
-- Les modèles (vues select * / select cols) se créent par-dessus → 0 ligne → tests PASS.
-- Compatible postgres 16 + duckdb (types INTEGER/BIGINT/VARCHAR/DOUBLE PRECISION/DATE/BOOLEAN/TIMESTAMP).
CREATE SCHEMA IF NOT EXISTS star_public;

CREATE TABLE IF NOT EXISTS star_public.dim_asset (
    asset_sk INTEGER, asset_id INTEGER, ticker VARCHAR, name VARCHAR, tier INTEGER,
    contract_address VARCHAR, sources_confirmed INTEGER, single_source BOOLEAN,
    methodology_version VARCHAR, valid_from DATE, valid_to DATE, is_current BOOLEAN
);

CREATE TABLE IF NOT EXISTS star_public.fact_market_snapshot (
    asset_sk INTEGER, asset_id INTEGER, snapshot_date DATE, date_key INTEGER,
    price_consensus_usd DOUBLE PRECISION, supply_on_chain BIGINT,
    market_cap_derived_usd DOUBLE PRECISION, tier_crypto INTEGER,
    exchanges_count INTEGER, methodology_version VARCHAR
);

CREATE TABLE IF NOT EXISTS star_public.fact_ai_analysis (
    ai_analysis_sk INTEGER, asset_sk INTEGER, analysis_type_id VARCHAR, date_sk INTEGER,
    generated_date DATE, model_id VARCHAR, prompt_version VARCHAR, content_json VARCHAR,
    methodology_version VARCHAR
);

CREATE TABLE IF NOT EXISTS star_public.sat_asset_market_derived (
    asset_sk INTEGER, asset_id INTEGER, load_ts TIMESTAMP
);

CREATE TABLE IF NOT EXISTS star_public.sat_asset_metadata_public (
    asset_sk INTEGER, asset_id INTEGER, load_ts TIMESTAMP
);

CREATE TABLE IF NOT EXISTS star_public.sat_asset_news_public (
    asset_sk INTEGER, asset_id INTEGER, load_ts TIMESTAMP
);

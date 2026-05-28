-- =============================================================================
-- validate_macros_xdb — compile-time smoke test for cross-DB macros.
--
-- Purpose: assert that the 3 xdb macros render without syntax error on the
--          current target adapter. dbt compile / dbt parse validates Jinja
--          expansion; no DB connection is needed for this file.
--
-- Run:
--   dbt compile --select validate_macros_xdb        (postgres target)
--
-- DuckDB path validation:
--   Set target.type = 'duckdb' in profiles.yml or via --vars override
--   (requires dbt-duckdb adapter installed). The compiler error branch is
--   tested implicitly: any unsupported adapter raises at parse time.
-- =============================================================================

select
    -- hash_diff_xdb: md5 of concatenated columns
    {{ hash_diff_xdb(['symbol', 'chain_id', 'source_record']) }}   as hash_diff_result,

    -- json_extract_xdb: text extraction from JSON column
    {{ json_extract_xdb('metadata_raw', 'sector') }}               as json_sector,
    {{ json_extract_xdb('metadata_raw', 'tags') }}                 as json_tags,

    -- current_timestamp_xdb: timezone-aware timestamp
    {{ current_timestamp_xdb() }}                                  as loaded_at

from (select null::text as symbol,
             null::text as chain_id,
             null::text as source_record,
             null::jsonb as metadata_raw) _dummy

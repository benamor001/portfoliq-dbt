{#
  hash_diff_xdb — cross-DB hash of concatenated column values.

  Computes md5(concat_ws('|', col1, col2, ...)) on both postgres and duckdb.
  md5 is available natively on both adapters (DuckDB 0.10+).

  Usage:
    {{ hash_diff_xdb(['symbol', 'name', 'chain_id']) }}

  Parameters:
    columns_list — list of column expressions to hash together

  Notes:
    - Columns are concatenated with '|' as separator (safe for financial identifiers).
    - NULL columns are treated as empty string by concat_ws on both adapters.
    - Result is a lowercase 32-char hex string on both targets (md5 output).
    - Raises a compile-time error on unsupported adapters (no silent fallback).
#}
{% macro hash_diff_xdb(columns_list) %}
  {% if columns_list | length == 0 %}
    {% do exceptions.raise_compiler_error(
      "hash_diff_xdb requires at least one column. Got an empty list."
    ) %}
  {% endif %}

  {% set cols_sql = columns_list | join(', ') %}

  {% if target.type == 'postgres' %}
    md5(concat_ws('|', {{ cols_sql }}))
  {% elif target.type == 'duckdb' %}
    md5(concat_ws('|', {{ cols_sql }}))
  {% else %}
    {% do exceptions.raise_compiler_error(
      "hash_diff_xdb: adapter '" ~ target.type ~ "' is not supported. Supported: postgres, duckdb."
    ) %}
  {% endif %}
{% endmacro %}

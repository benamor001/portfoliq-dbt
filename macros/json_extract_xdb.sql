{#
  json_extract_xdb — cross-DB JSON key extractor.

  Extracts a text value from a JSON column by key name.

  Usage:
    {{ json_extract_xdb('metadata', 'sector') }}
    -- postgres  → metadata->>'sector'
    -- duckdb    → json_extract_string(metadata, '$.sector')

  Parameters:
    column — column expression holding the JSON value (unquoted identifier or expression)
    key    — the JSON object key to extract (string, dot notation not supported here)

  Notes:
    - Always returns TEXT (not JSON). For nested paths use nested calls or extend key.
    - On postgres, uses the ->> operator (text extraction), not -> (json extraction).
    - On duckdb, wraps with the JSONPath prefix '$.' as required by json_extract_string().
    - Raises a compile-time error on unsupported adapters (no silent fallback).
#}
{% macro json_extract_xdb(column, key) %}
  {% if target.type == 'postgres' %}
    {{ column }}->>'{{ key }}'
  {% elif target.type == 'duckdb' %}
    json_extract_string({{ column }}, '$.{{ key }}')
  {% else %}
    {% do exceptions.raise_compiler_error(
      "json_extract_xdb: adapter '" ~ target.type ~ "' is not supported. Supported: postgres, duckdb."
    ) %}
  {% endif %}
{% endmacro %}

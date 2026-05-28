{#
  current_timestamp_xdb — cross-DB current timestamp expression.

  Returns the current timestamp as a timestamptz-compatible expression.

  Usage:
    {{ current_timestamp_xdb() }}
    -- postgres  → current_timestamp::timestamptz
    -- duckdb    → current_timestamp

  Notes:
    - On postgres, the explicit ::timestamptz cast ensures the type is unambiguous
      in contexts where the planner needs a timestamptz (e.g. satellite load_date columns).
    - On duckdb, current_timestamp natively returns TIMESTAMP WITH TIME ZONE — no cast needed.
    - Both targets produce a timezone-aware value, safe for load_date and snapshot columns.
    - Raises a compile-time error on unsupported adapters (no silent fallback).
#}
{% macro current_timestamp_xdb() %}
  {% if target.type == 'postgres' %}
    current_timestamp::timestamptz
  {% elif target.type == 'duckdb' %}
    current_timestamp
  {% else %}
    {% do exceptions.raise_compiler_error(
      "current_timestamp_xdb: adapter '" ~ target.type ~ "' is not supported. Supported: postgres, duckdb."
    ) %}
  {% endif %}
{% endmacro %}

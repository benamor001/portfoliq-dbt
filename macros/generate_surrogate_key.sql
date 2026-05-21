{#
  generate_surrogate_key — wrapper around dbt_utils.generate_surrogate_key
  with input validation.

  Validates that the columns list is non-empty before delegating to dbt_utils.
  Raises a compile-time error if an empty list is passed (silent hashing bugs).

  Usage:
    {{ portfoliq_surrogate_key(['asset_sk', 'snapshot_date']) }}

  This is a named wrapper (portfoliq_surrogate_key) to avoid colliding with the
  dbt_utils macro of the same name in consumer projects.
#}
{% macro portfoliq_surrogate_key(column_names) %}
  {% if column_names | length == 0 %}
    {% do exceptions.raise_compiler_error(
      "portfoliq_surrogate_key requires at least one column. Got an empty list."
    ) %}
  {% endif %}
  {{ dbt_utils.generate_surrogate_key(column_names) }}
{% endmacro %}

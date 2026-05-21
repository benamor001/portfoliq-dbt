{#
  assert_star_enabled — guard macro for portfoliq pack models.

  Raises a compile-time error if portfoliq_enable_star is false and
  a model is being referenced/executed. This prevents silent empty-set
  queries from propagating through consumer pipelines without warning.

  Usage (in any model that requires star access):
    {{ assert_star_enabled() }}

  In dbt_project.yml the var portfoliq_enable_star defaults to true.
  Set it to false to disable all pack models cleanly.
#}
{% macro assert_star_enabled() %}
  {% if not var('portfoliq_enable_star', true) %}
    {% do exceptions.raise_compiler_error(
      "portfoliq_enable_star is set to false. "
      ~ "This model will not execute. "
      ~ "Set var portfoliq_enable_star: true in your dbt_project.yml or --vars to enable the portfoliq pack."
    ) %}
  {% endif %}
{% endmacro %}

{#
  get_star_source_name — helper to resolve the star_public schema name.

  Returns the schema name to use for star_public tables, allowing consumers
  to override the schema in dev/test environments without changing every model.

  In production: schema = 'star_public' (portfolIQ pipeline default).
  Override via var portfoliq_star_schema in dbt_project.yml or --vars.

  Usage:
    {{ get_star_source_name() }}  → 'star_public' (default)

  Note: This is a utility helper. The primary connection is via sources.yml
  which already points to star_public. Use this macro for raw SQL references
  in analyses/ or examples/ only — prefer source() in models.
#}
{% macro get_star_source_name() %}
  {{ var('portfoliq_star_schema', 'star_public') }}
{% endmacro %}

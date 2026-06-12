{#
  safe_divide — NULL-safe division helper.

  Returns NULL when the denominator is zero or NULL.
  Useful for computing P/S, P/R ratios where revenue or fees may be zero.

  Usage:
    {{ safe_divide('market_cap_derived_usd', 'revenue_30d_usd') }}
    {{ safe_divide('market_cap_derived_usd', 'fees_30d_usd', default=0) }}

  Parameters:
    numerator   — expression for the dividend
    denominator — expression for the divisor
    default     — value to return when denominator is zero/NULL (default: NULL)
#}
{% macro safe_divide(numerator, denominator, default='null') %}
case
    when {{ denominator }} is null or {{ denominator }} = 0 then {{ default }}
    else {{ numerator }} / {{ denominator }}
end
{% endmacro %}

{% macro safe_divide(numerator, denominator) -%}
  (cast({{ numerator }} as float) / nullif({{ denominator }}, 0))
{%- endmacro %}

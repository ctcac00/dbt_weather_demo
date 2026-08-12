{{
  config(
    materialized='incremental',
    unique_key='forecast_accuracy_key',
    incremental_strategy='merge'
  )
}}

select
    forecast_accuracy_key,
    forecast_id,
    station_id,
    region,
    station_type,
    sector_focus,
    issued_at,
    valid_at,
    forecast_valid_date,
    horizon_hours,
    model_run_id,
    forecast_temperature_c,
    observed_temperature_c,
    absolute_temperature_error_c,
    forecast_precipitation_mm,
    observed_precipitation_mm,
    absolute_precipitation_error_mm,
    forecast_wind_gust_kph,
    observed_wind_gust_kph,
    absolute_wind_gust_error_kph,
    temperature_within_one_degree,
    precipitation_event_correct,
    precipitation_error_ratio
from {{ ref('int_forecast_accuracy') }}

{% if is_incremental() %}
where forecast_valid_date >= (
    select coalesce(dateadd(day, -2, max(forecast_valid_date)), '1900-01-01'::date)
    from {{ this }}
)
{% endif %}

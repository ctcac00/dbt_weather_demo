{{
  config(
    materialized='incremental',
    unique_key='forecast_accuracy_key',
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
  )
}}

with int_forecast_accuracy as (

    select * from {{ ref('int_forecast_accuracy') }}

),

final as (

    select
        int_forecast_accuracy.forecast_accuracy_key,
        int_forecast_accuracy.forecast_id,
        int_forecast_accuracy.station_id,
        int_forecast_accuracy.region,
        int_forecast_accuracy.station_type,
        int_forecast_accuracy.sector_focus,
        int_forecast_accuracy.issued_at,
        int_forecast_accuracy.valid_at,
        int_forecast_accuracy.forecast_valid_date,
        int_forecast_accuracy.horizon_hours,
        int_forecast_accuracy.model_run_id,
        int_forecast_accuracy.forecast_temperature_c,
        int_forecast_accuracy.observed_temperature_c,
        int_forecast_accuracy.absolute_temperature_error_c,
        int_forecast_accuracy.forecast_precipitation_mm,
        int_forecast_accuracy.observed_precipitation_mm,
        int_forecast_accuracy.absolute_precipitation_error_mm,
        int_forecast_accuracy.forecast_wind_gust_kph,
        int_forecast_accuracy.observed_wind_gust_kph,
        int_forecast_accuracy.absolute_wind_gust_error_kph,
        int_forecast_accuracy.temperature_within_one_degree,
        int_forecast_accuracy.precipitation_event_correct,
        int_forecast_accuracy.precipitation_error_ratio
    from int_forecast_accuracy

    {% if is_incremental() %}
    where int_forecast_accuracy.forecast_valid_date >= (
        select coalesce(dateadd(day, -2, max(forecast_valid_date)), '1900-01-01'::date)
        from {{ this }}
    )
    {% endif %}

)

select * from final

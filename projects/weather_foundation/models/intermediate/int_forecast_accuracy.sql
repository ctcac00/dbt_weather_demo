with stg_forecasts as (

    select * from {{ ref('stg_forecasts') }}

),

stg_stations as (

    select * from {{ ref('stg_stations') }}

),

forecast_accuracy as (

    select
        {{ dbt_utils.generate_surrogate_key(['stg_forecasts.forecast_id', 'stg_forecasts.valid_at']) }} as forecast_accuracy_key,
        stg_forecasts.forecast_id,
        stg_forecasts.station_id,
        stg_stations.region,
        stg_stations.station_type,
        stg_stations.sector_focus,
        stg_forecasts.issued_at,
        stg_forecasts.valid_at,
        cast(stg_forecasts.valid_at as date) as forecast_valid_date,
        stg_forecasts.horizon_hours,
        stg_forecasts.model_run_id,
        stg_forecasts.forecast_temperature_c,
        stg_forecasts.observed_temperature_c,
        abs(stg_forecasts.forecast_temperature_c - stg_forecasts.observed_temperature_c) as absolute_temperature_error_c,
        stg_forecasts.forecast_precipitation_mm,
        stg_forecasts.observed_precipitation_mm,
        abs(stg_forecasts.forecast_precipitation_mm - stg_forecasts.observed_precipitation_mm) as absolute_precipitation_error_mm,
        stg_forecasts.forecast_wind_gust_kph,
        stg_forecasts.observed_wind_gust_kph,
        abs(stg_forecasts.forecast_wind_gust_kph - stg_forecasts.observed_wind_gust_kph) as absolute_wind_gust_error_kph,
        case
            when abs(stg_forecasts.forecast_temperature_c - stg_forecasts.observed_temperature_c) <= 1.0 then true
            else false
        end as temperature_within_one_degree,
        case
            when stg_forecasts.observed_precipitation_mm >= 5 and stg_forecasts.forecast_precipitation_mm >= 5 then true
            when stg_forecasts.observed_precipitation_mm < 5 and stg_forecasts.forecast_precipitation_mm < 5 then true
            else false
        end as precipitation_event_correct,
        {{ safe_divide('abs(stg_forecasts.forecast_precipitation_mm - stg_forecasts.observed_precipitation_mm)', 'nullif(stg_forecasts.observed_precipitation_mm, 0)') }} as precipitation_error_ratio
    from stg_forecasts
    inner join stg_stations
        on stg_forecasts.station_id = stg_stations.station_id

),

final as (

    select
        forecast_accuracy.forecast_accuracy_key,
        forecast_accuracy.forecast_id,
        forecast_accuracy.station_id,
        forecast_accuracy.region,
        forecast_accuracy.station_type,
        forecast_accuracy.sector_focus,
        forecast_accuracy.issued_at,
        forecast_accuracy.valid_at,
        forecast_accuracy.forecast_valid_date,
        forecast_accuracy.horizon_hours,
        forecast_accuracy.model_run_id,
        forecast_accuracy.forecast_temperature_c,
        forecast_accuracy.observed_temperature_c,
        forecast_accuracy.absolute_temperature_error_c,
        forecast_accuracy.forecast_precipitation_mm,
        forecast_accuracy.observed_precipitation_mm,
        forecast_accuracy.absolute_precipitation_error_mm,
        forecast_accuracy.forecast_wind_gust_kph,
        forecast_accuracy.observed_wind_gust_kph,
        forecast_accuracy.absolute_wind_gust_error_kph,
        forecast_accuracy.temperature_within_one_degree,
        forecast_accuracy.precipitation_event_correct,
        forecast_accuracy.precipitation_error_ratio
    from forecast_accuracy

)

select * from final

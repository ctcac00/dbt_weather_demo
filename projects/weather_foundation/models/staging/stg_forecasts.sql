with raw_forecasts as (

    select * from {{ ref('raw_forecasts') }}

),

final as (

    select
        cast(raw_forecasts.forecast_id as varchar) as forecast_id,
        cast(raw_forecasts.station_id as varchar) as station_id,
        cast(raw_forecasts.issued_at as timestamp_ntz) as issued_at,
        cast(raw_forecasts.valid_at as timestamp_ntz) as valid_at,
        cast(raw_forecasts.horizon_hours as number(10, 0)) as horizon_hours,
        cast(raw_forecasts.forecast_temperature_c as float) as forecast_temperature_c,
        cast(raw_forecasts.observed_temperature_c as float) as observed_temperature_c,
        cast(raw_forecasts.forecast_precipitation_mm as float) as forecast_precipitation_mm,
        cast(raw_forecasts.observed_precipitation_mm as float) as observed_precipitation_mm,
        cast(raw_forecasts.forecast_wind_gust_kph as float) as forecast_wind_gust_kph,
        cast(raw_forecasts.observed_wind_gust_kph as float) as observed_wind_gust_kph,
        cast(raw_forecasts.model_run_id as varchar) as model_run_id
    from raw_forecasts

)

select * from final

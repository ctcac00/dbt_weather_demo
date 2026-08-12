select
    {{ dbt_utils.generate_surrogate_key(['forecasts.forecast_id', 'forecasts.valid_at']) }} as forecast_accuracy_key,
    forecasts.forecast_id,
    forecasts.station_id,
    stations.region,
    stations.station_type,
    stations.sector_focus,
    forecasts.issued_at,
    forecasts.valid_at,
    cast(forecasts.valid_at as date) as forecast_valid_date,
    forecasts.horizon_hours,
    forecasts.model_run_id,
    forecasts.forecast_temperature_c,
    forecasts.observed_temperature_c,
    abs(forecasts.forecast_temperature_c - forecasts.observed_temperature_c) as absolute_temperature_error_c,
    forecasts.forecast_precipitation_mm,
    forecasts.observed_precipitation_mm,
    abs(forecasts.forecast_precipitation_mm - forecasts.observed_precipitation_mm) as absolute_precipitation_error_mm,
    forecasts.forecast_wind_gust_kph,
    forecasts.observed_wind_gust_kph,
    abs(forecasts.forecast_wind_gust_kph - forecasts.observed_wind_gust_kph) as absolute_wind_gust_error_kph,
    case
        when abs(forecasts.forecast_temperature_c - forecasts.observed_temperature_c) <= 1.0 then true
        else false
    end as temperature_within_one_degree,
    case
        when forecasts.observed_precipitation_mm >= 5 and forecasts.forecast_precipitation_mm >= 5 then true
        when forecasts.observed_precipitation_mm < 5 and forecasts.forecast_precipitation_mm < 5 then true
        else false
    end as precipitation_event_correct,
    {{ safe_divide('abs(forecasts.forecast_precipitation_mm - forecasts.observed_precipitation_mm)', 'nullif(forecasts.observed_precipitation_mm, 0)') }} as precipitation_error_ratio
from {{ ref('stg_forecasts') }} as forecasts
inner join {{ ref('stg_stations') }} as stations
    on forecasts.station_id = stations.station_id

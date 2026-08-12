select
    cast(forecast_id as varchar) as forecast_id,
    cast(station_id as varchar) as station_id,
    cast(issued_at as timestamp_ntz) as issued_at,
    cast(valid_at as timestamp_ntz) as valid_at,
    cast(horizon_hours as number(10, 0)) as horizon_hours,
    cast(forecast_temperature_c as float) as forecast_temperature_c,
    cast(observed_temperature_c as float) as observed_temperature_c,
    cast(forecast_precipitation_mm as float) as forecast_precipitation_mm,
    cast(observed_precipitation_mm as float) as observed_precipitation_mm,
    cast(forecast_wind_gust_kph as float) as forecast_wind_gust_kph,
    cast(observed_wind_gust_kph as float) as observed_wind_gust_kph,
    cast(model_run_id as varchar) as model_run_id
from {{ ref('raw_forecasts') }}

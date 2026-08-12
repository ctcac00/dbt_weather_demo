select
    cast(observation_id as varchar) as observation_id,
    cast(station_id as varchar) as station_id,
    cast(observed_at as timestamp_ntz) as observed_at,
    cast(temperature_c as float) as temperature_c,
    cast(precipitation_mm as float) as precipitation_mm,
    cast(wind_speed_kph as float) as wind_speed_kph,
    cast(wind_gust_kph as float) as wind_gust_kph,
    cast(visibility_km as float) as visibility_km,
    cast(humidity_pct as float) as humidity_pct,
    cast(pressure_hpa as float) as pressure_hpa
from {{ ref('raw_observations') }}

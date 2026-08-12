with station_day as (
    select
        observations.station_id,
        cast(observations.observed_at as date) as observation_date,
        count(*) as observation_count,
        avg(observations.temperature_c) as average_temperature_c,
        min(observations.temperature_c) as minimum_temperature_c,
        max(observations.temperature_c) as maximum_temperature_c,
        sum(observations.precipitation_mm) as total_precipitation_mm,
        avg(observations.wind_speed_kph) as average_wind_speed_kph,
        max(observations.wind_gust_kph) as maximum_wind_gust_kph,
        min(observations.visibility_km) as minimum_visibility_km,
        avg(observations.humidity_pct) as average_humidity_pct,
        avg(observations.pressure_hpa) as average_pressure_hpa,
        max(case when observations.precipitation_mm > 0 then 1 else 0 end) = 1 as precipitation_observed,
        max(case when observations.visibility_km < 5 then 1 else 0 end) = 1 as low_visibility_observed,
        max(case when observations.wind_gust_kph >= 50 then 1 else 0 end) = 1 as high_wind_observed,
        min(observations.temperature_c) <= 0 as freezing_observed
    from {{ ref('stg_observations') }} as observations
    group by observations.station_id, cast(observations.observed_at as date)
)

select
    {{ dbt_utils.generate_surrogate_key(['station_day.station_id', 'station_day.observation_date']) }} as station_daily_conditions_key,
    station_day.station_id,
    stations.station_name,
    stations.region,
    stations.station_type,
    stations.sector_focus,
    station_day.observation_date,
    cast(station_day.observation_count as number(18, 0)) as observation_count,
    station_day.average_temperature_c,
    station_day.minimum_temperature_c,
    station_day.maximum_temperature_c,
    station_day.total_precipitation_mm,
    station_day.average_wind_speed_kph,
    station_day.maximum_wind_gust_kph,
    station_day.minimum_visibility_km,
    station_day.average_humidity_pct,
    station_day.average_pressure_hpa,
    station_day.precipitation_observed,
    station_day.low_visibility_observed,
    station_day.high_wind_observed,
    station_day.freezing_observed
from station_day
inner join {{ ref('stg_stations') }} as stations
    on station_day.station_id = stations.station_id

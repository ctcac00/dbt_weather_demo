with stg_observations as (

    select * from {{ ref('stg_observations') }}

),

stg_stations as (

    select * from {{ ref('stg_stations') }}

),

station_day as (

    select
        stg_observations.station_id,
        cast(stg_observations.observed_at as date) as observation_date,
        count(*) as observation_count,
        avg(stg_observations.temperature_c) as average_temperature_c,
        min(stg_observations.temperature_c) as minimum_temperature_c,
        max(stg_observations.temperature_c) as maximum_temperature_c,
        sum(stg_observations.precipitation_mm) as total_precipitation_mm,
        avg(stg_observations.wind_speed_kph) as average_wind_speed_kph,
        max(stg_observations.wind_gust_kph) as maximum_wind_gust_kph,
        min(stg_observations.visibility_km) as minimum_visibility_km,
        avg(stg_observations.humidity_pct) as average_humidity_pct,
        avg(stg_observations.pressure_hpa) as average_pressure_hpa,
        max(case when stg_observations.precipitation_mm > 0 then 1 else 0 end) = 1 as precipitation_observed,
        max(case when stg_observations.visibility_km < 5 then 1 else 0 end) = 1 as low_visibility_observed,
        max(case when stg_observations.wind_gust_kph >= 50 then 1 else 0 end) = 1 as high_wind_observed,
        min(stg_observations.temperature_c) <= 0 as freezing_observed
    from stg_observations
    group by stg_observations.station_id, cast(stg_observations.observed_at as date)

),

daily_conditions as (

    select
        {{ dbt_utils.generate_surrogate_key(['station_day.station_id', 'station_day.observation_date']) }} as station_daily_conditions_key,
        station_day.station_id,
        stg_stations.station_name,
        stg_stations.region,
        stg_stations.station_type,
        stg_stations.sector_focus,
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
    inner join stg_stations
        on station_day.station_id = stg_stations.station_id

),

final as (

    select
        daily_conditions.station_daily_conditions_key,
        daily_conditions.station_id,
        daily_conditions.station_name,
        daily_conditions.region,
        daily_conditions.station_type,
        daily_conditions.sector_focus,
        daily_conditions.observation_date,
        daily_conditions.observation_count,
        daily_conditions.average_temperature_c,
        daily_conditions.minimum_temperature_c,
        daily_conditions.maximum_temperature_c,
        daily_conditions.total_precipitation_mm,
        daily_conditions.average_wind_speed_kph,
        daily_conditions.maximum_wind_gust_kph,
        daily_conditions.minimum_visibility_km,
        daily_conditions.average_humidity_pct,
        daily_conditions.average_pressure_hpa,
        daily_conditions.precipitation_observed,
        daily_conditions.low_visibility_observed,
        daily_conditions.high_wind_observed,
        daily_conditions.freezing_observed
    from daily_conditions

)

select * from final

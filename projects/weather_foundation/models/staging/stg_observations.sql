with raw_observations as (

    select * from {{ ref('raw_observations') }}

),

final as (

    select
        cast(raw_observations.observation_id as varchar) as observation_id,
        cast(raw_observations.station_id as varchar) as station_id,
        cast(raw_observations.observed_at as timestamp_ntz) as observed_at,
        cast(raw_observations.temperature_c as float) as temperature_c,
        cast(raw_observations.precipitation_mm as float) as precipitation_mm,
        cast(raw_observations.wind_speed_kph as float) as wind_speed_kph,
        cast(raw_observations.wind_gust_kph as float) as wind_gust_kph,
        cast(raw_observations.visibility_km as float) as visibility_km,
        cast(raw_observations.humidity_pct as float) as humidity_pct,
        cast(raw_observations.pressure_hpa as float) as pressure_hpa
    from raw_observations

)

select * from final

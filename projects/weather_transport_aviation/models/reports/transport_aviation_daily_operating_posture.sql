with daily_station_operating_posture as (

    select * from {{ ref('daily_station_operating_posture') }}

),

daily_operating_posture as (

    select
        daily_station_operating_posture.posture_date,
        daily_station_operating_posture.region,
        daily_station_operating_posture.operating_sector,
        count(distinct daily_station_operating_posture.station_id) as station_count,
        sum(daily_station_operating_posture.observation_count) as observation_count,
        avg(daily_station_operating_posture.average_temperature_error_c) as average_temperature_error_c,
        avg(daily_station_operating_posture.average_precipitation_error_mm) as average_precipitation_error_mm,
        avg(daily_station_operating_posture.average_wind_gust_error_kph) as average_wind_gust_error_kph,
        max(daily_station_operating_posture.maximum_wind_gust_kph) as maximum_wind_gust_kph,
        min(daily_station_operating_posture.minimum_visibility_km) as minimum_visibility_km,
        count_if(daily_station_operating_posture.low_visibility_observed) as low_visibility_station_count,
        count_if(daily_station_operating_posture.high_wind_observed) as high_wind_station_count,
        count_if(daily_station_operating_posture.freezing_observed) as freezing_station_count,
        sum(daily_station_operating_posture.alert_count) as alert_count,
        sum(daily_station_operating_posture.observed_incidents) as observed_incidents,
        max(daily_station_operating_posture.operating_posture_score) as maximum_operating_posture_score,
        avg(daily_station_operating_posture.operating_posture_score) as average_operating_posture_score,
        case
            when max(daily_station_operating_posture.operating_posture_score) >= 6 then 'disruption_likely'
            when max(daily_station_operating_posture.operating_posture_score) >= 4 then 'heightened_watch'
            else 'normal_operations'
        end as disruption_posture
    from daily_station_operating_posture
    where daily_station_operating_posture.operating_sector in ('aviation', 'rail', 'road')
    group by
        daily_station_operating_posture.posture_date,
        daily_station_operating_posture.region,
        daily_station_operating_posture.operating_sector

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['daily_operating_posture.posture_date', 'daily_operating_posture.region', 'daily_operating_posture.operating_sector']) }} as daily_operating_posture_key,
        daily_operating_posture.posture_date,
        daily_operating_posture.region,
        daily_operating_posture.operating_sector,
        daily_operating_posture.station_count,
        daily_operating_posture.observation_count,
        daily_operating_posture.average_temperature_error_c,
        daily_operating_posture.average_precipitation_error_mm,
        daily_operating_posture.average_wind_gust_error_kph,
        daily_operating_posture.maximum_wind_gust_kph,
        daily_operating_posture.minimum_visibility_km,
        daily_operating_posture.low_visibility_station_count,
        daily_operating_posture.high_wind_station_count,
        daily_operating_posture.freezing_station_count,
        daily_operating_posture.alert_count,
        daily_operating_posture.observed_incidents,
        daily_operating_posture.maximum_operating_posture_score,
        daily_operating_posture.average_operating_posture_score,
        daily_operating_posture.disruption_posture
    from daily_operating_posture

)

select * from final

select
    {{ dbt_utils.generate_surrogate_key(['posture_date', 'region', 'operating_sector']) }} as daily_operating_posture_key,
    posture_date,
    region,
    operating_sector,
    count(distinct station_id) as station_count,
    sum(observation_count) as observation_count,
    avg(average_temperature_error_c) as average_temperature_error_c,
    avg(average_precipitation_error_mm) as average_precipitation_error_mm,
    avg(average_wind_gust_error_kph) as average_wind_gust_error_kph,
    max(maximum_wind_gust_kph) as maximum_wind_gust_kph,
    min(minimum_visibility_km) as minimum_visibility_km,
    count_if(low_visibility_observed) as low_visibility_station_count,
    count_if(high_wind_observed) as high_wind_station_count,
    count_if(freezing_observed) as freezing_station_count,
    sum(alert_count) as alert_count,
    sum(observed_incidents) as observed_incidents,
    max(operating_posture_score) as maximum_operating_posture_score,
    avg(operating_posture_score) as average_operating_posture_score,
    case
        when max(operating_posture_score) >= 6 then 'disruption_likely'
        when max(operating_posture_score) >= 4 then 'heightened_watch'
        else 'normal_operations'
    end as disruption_posture
from {{ ref('daily_station_operating_posture') }}
where operating_sector in ('aviation', 'rail', 'road')
group by posture_date, region, operating_sector

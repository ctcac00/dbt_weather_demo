select
    {{ dbt_utils.generate_surrogate_key(['forecast_valid_date', 'region', 'operating_sector']) }} as operating_risk_key,
    forecast_valid_date,
    region,
    operating_sector,
    count(distinct station_id) as station_count,
    avg(absolute_temperature_error_c) as average_temperature_error_c,
    avg(absolute_precipitation_error_mm) as average_precipitation_error_mm,
    avg(absolute_wind_gust_error_kph) as average_wind_gust_error_kph,
    max(operating_risk_score) as max_operating_risk_score,
    avg(operating_risk_score) as average_operating_risk_score,
    case
        when max(operating_risk_score) >= 6 then 'disruption_likely'
        when max(operating_risk_score) >= 4 then 'heightened_watch'
        else 'normal_operations'
    end as operating_risk_band
from {{ ref('sector_operating_risk') }}
where operating_sector in ('aviation', 'rail', 'road')
group by forecast_valid_date, region, operating_sector

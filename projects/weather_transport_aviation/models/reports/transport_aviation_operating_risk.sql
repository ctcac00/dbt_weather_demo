with sector_operating_risk as (

    select * from {{ ref('sector_operating_risk') }}

),

operating_risk as (

    select
        sector_operating_risk.forecast_valid_date,
        sector_operating_risk.region,
        sector_operating_risk.operating_sector,
        max(sector_operating_risk.data_service_adoption_key) as data_service_adoption_key,
        count(distinct sector_operating_risk.station_id) as station_count,
        max(sector_operating_risk.active_subscription_count) as active_subscription_count,
        max(sector_operating_risk.active_api_calls_30d) as active_api_calls_30d,
        max(sector_operating_risk.alert_opt_in_rate) as alert_opt_in_rate,
        max(sector_operating_risk.adoption_band) as adoption_band,
        avg(sector_operating_risk.absolute_temperature_error_c) as average_temperature_error_c,
        avg(sector_operating_risk.absolute_precipitation_error_mm) as average_precipitation_error_mm,
        avg(sector_operating_risk.absolute_wind_gust_error_kph) as average_wind_gust_error_kph,
        max(sector_operating_risk.operating_risk_score) as max_operating_risk_score,
        avg(sector_operating_risk.operating_risk_score) as average_operating_risk_score,
        case
            when max(sector_operating_risk.operating_risk_score) >= 6 then 'disruption_likely'
            when max(sector_operating_risk.operating_risk_score) >= 4 then 'heightened_watch'
            else 'normal_operations'
        end as operating_risk_band
    from sector_operating_risk
    where sector_operating_risk.operating_sector in ('aviation', 'rail', 'road')
    group by
        sector_operating_risk.forecast_valid_date,
        sector_operating_risk.region,
        sector_operating_risk.operating_sector

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['operating_risk.forecast_valid_date', 'operating_risk.region', 'operating_risk.operating_sector']) }} as operating_risk_key,
        operating_risk.forecast_valid_date,
        operating_risk.region,
        operating_risk.operating_sector,
        operating_risk.data_service_adoption_key,
        operating_risk.station_count,
        operating_risk.active_subscription_count,
        operating_risk.active_api_calls_30d,
        operating_risk.alert_opt_in_rate,
        operating_risk.adoption_band,
        operating_risk.average_temperature_error_c,
        operating_risk.average_precipitation_error_mm,
        operating_risk.average_wind_gust_error_kph,
        operating_risk.max_operating_risk_score,
        operating_risk.average_operating_risk_score,
        operating_risk.operating_risk_band
    from operating_risk

)

select * from final

with transport_station_readiness as (

    select * from {{ ref('transport_station_readiness') }}

),

sector_readiness as (

    select
        transport_station_readiness.readiness_date,
        transport_station_readiness.region,
        transport_station_readiness.operating_sector,
        max(transport_station_readiness.region_service_context_key) as region_service_context_key,
        max(transport_station_readiness.service_context_band) as service_context_band,
        count(distinct transport_station_readiness.station_id) as station_count,
        sum(transport_station_readiness.observation_count) as observation_count,
        sum(transport_station_readiness.forecast_count) as forecast_count,
        sum(transport_station_readiness.alert_count) as alert_count,
        sum(transport_station_readiness.observed_incidents) as observed_incidents,
        max(transport_station_readiness.active_subscription_count) as active_subscription_count,
        max(transport_station_readiness.active_api_calls_30d) as active_api_calls_30d,
        max(transport_station_readiness.regional_alert_opt_in_rate) as regional_alert_opt_in_rate,
        sum(transport_station_readiness.active_sector_subscription_count) as active_sector_subscription_count,
        sum(transport_station_readiness.active_sector_api_calls_30d) as active_sector_api_calls_30d,
        avg(transport_station_readiness.average_temperature_error_c) as average_temperature_error_c,
        avg(transport_station_readiness.average_precipitation_error_mm) as average_precipitation_error_mm,
        avg(transport_station_readiness.average_wind_gust_error_kph) as average_wind_gust_error_kph,
        max(transport_station_readiness.maximum_wind_gust_kph) as maximum_wind_gust_kph,
        min(transport_station_readiness.minimum_visibility_km) as minimum_visibility_km,
        count_if(transport_station_readiness.low_visibility_observed) as low_visibility_station_count,
        count_if(transport_station_readiness.high_wind_observed) as high_wind_station_count,
        count_if(transport_station_readiness.freezing_observed) as freezing_station_count,
        avg(transport_station_readiness.weather_readiness_score) as average_weather_readiness_score,
        min(transport_station_readiness.weather_readiness_score) as minimum_weather_readiness_score,
        max(transport_station_readiness.maximum_alert_severity_weight) as maximum_alert_severity_weight,
        max(transport_station_readiness.transport_readiness_status) as highest_transport_readiness_status,
        case
            when min(transport_station_readiness.weather_readiness_score) < 50
                or max(transport_station_readiness.maximum_alert_severity_weight) >= 3 then 'ground_stop_watch'
            when min(transport_station_readiness.weather_readiness_score) < 70
                or count_if(transport_station_readiness.low_visibility_observed or transport_station_readiness.high_wind_observed) > 0 then 'operational_constraints'
            else 'normal_operations'
        end as transport_readiness_band
    from transport_station_readiness
    where transport_station_readiness.operating_sector in ('aviation', 'rail', 'road')
    group by
        transport_station_readiness.readiness_date,
        transport_station_readiness.region,
        transport_station_readiness.operating_sector

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['sector_readiness.readiness_date', 'sector_readiness.region', 'sector_readiness.operating_sector']) }} as transport_sector_readiness_key,
        sector_readiness.readiness_date,
        sector_readiness.region,
        sector_readiness.operating_sector,
        sector_readiness.region_service_context_key,
        sector_readiness.service_context_band,
        sector_readiness.station_count,
        sector_readiness.observation_count,
        sector_readiness.forecast_count,
        sector_readiness.alert_count,
        sector_readiness.observed_incidents,
        sector_readiness.active_subscription_count,
        sector_readiness.active_api_calls_30d,
        sector_readiness.regional_alert_opt_in_rate,
        sector_readiness.active_sector_subscription_count,
        sector_readiness.active_sector_api_calls_30d,
        sector_readiness.average_temperature_error_c,
        sector_readiness.average_precipitation_error_mm,
        sector_readiness.average_wind_gust_error_kph,
        sector_readiness.maximum_wind_gust_kph,
        sector_readiness.minimum_visibility_km,
        sector_readiness.low_visibility_station_count,
        sector_readiness.high_wind_station_count,
        sector_readiness.freezing_station_count,
        sector_readiness.average_weather_readiness_score,
        sector_readiness.minimum_weather_readiness_score,
        sector_readiness.maximum_alert_severity_weight,
        sector_readiness.highest_transport_readiness_status,
        sector_readiness.transport_readiness_band
    from sector_readiness

)

select * from final

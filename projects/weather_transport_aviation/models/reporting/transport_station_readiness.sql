with fct_station_weather_readiness as (

    select * from {{ ref('weather_foundation', 'fct_station_weather_readiness') }}

),

dim_region_service_context as (

    select * from {{ ref('weather_foundation', 'dim_region_service_context') }}

),

station_readiness as (

    select
        fct_station_weather_readiness.station_weather_readiness_key,
        fct_station_weather_readiness.station_daily_conditions_key,
        fct_station_weather_readiness.station_id,
        fct_station_weather_readiness.station_name,
        fct_station_weather_readiness.region,
        fct_station_weather_readiness.station_type,
        fct_station_weather_readiness.sector_focus,
        case
            when fct_station_weather_readiness.sector_focus in ('aviation', 'rail', 'road') then fct_station_weather_readiness.sector_focus
            when fct_station_weather_readiness.station_type = 'airport' then 'aviation'
            when fct_station_weather_readiness.station_type = 'transport' then 'rail'
            else 'general_transport'
        end as operating_sector,
        fct_station_weather_readiness.readiness_date,
        fct_station_weather_readiness.observation_count,
        fct_station_weather_readiness.maximum_wind_gust_kph,
        fct_station_weather_readiness.minimum_visibility_km,
        fct_station_weather_readiness.low_visibility_observed,
        fct_station_weather_readiness.high_wind_observed,
        fct_station_weather_readiness.freezing_observed,
        fct_station_weather_readiness.forecast_count,
        fct_station_weather_readiness.average_temperature_error_c,
        fct_station_weather_readiness.average_precipitation_error_mm,
        fct_station_weather_readiness.average_wind_gust_error_kph,
        fct_station_weather_readiness.precipitation_miss_observed,
        fct_station_weather_readiness.alert_count,
        fct_station_weather_readiness.maximum_alert_severity_weight,
        fct_station_weather_readiness.maximum_weighted_impact_score,
        fct_station_weather_readiness.observed_incidents,
        fct_station_weather_readiness.active_subscription_count,
        fct_station_weather_readiness.active_api_calls_30d,
        fct_station_weather_readiness.regional_alert_opt_in_rate,
        fct_station_weather_readiness.active_sector_subscription_count,
        fct_station_weather_readiness.active_sector_api_calls_30d,
        fct_station_weather_readiness.weather_readiness_score,
        fct_station_weather_readiness.weather_readiness_band,
        dim_region_service_context.region_service_context_key,
        dim_region_service_context.service_context_band,
        dim_region_service_context.airport_station_count,
        dim_region_service_context.transport_station_count,
        case
            when fct_station_weather_readiness.weather_readiness_score < 50
                or fct_station_weather_readiness.maximum_alert_severity_weight >= 3 then 'ground_stop_watch'
            when fct_station_weather_readiness.weather_readiness_score < 70
                or fct_station_weather_readiness.low_visibility_observed
                or fct_station_weather_readiness.high_wind_observed then 'operational_constraints'
            else 'normal_operations'
        end as transport_readiness_status
    from fct_station_weather_readiness
    inner join dim_region_service_context
        on fct_station_weather_readiness.region = dim_region_service_context.region
    where fct_station_weather_readiness.sector_focus in ('aviation', 'rail', 'road')
        or fct_station_weather_readiness.station_type in ('airport', 'transport')

),

final as (

    select
        station_readiness.station_weather_readiness_key,
        station_readiness.station_daily_conditions_key,
        station_readiness.station_id,
        station_readiness.station_name,
        station_readiness.region,
        station_readiness.station_type,
        station_readiness.sector_focus,
        station_readiness.operating_sector,
        station_readiness.readiness_date,
        station_readiness.observation_count,
        station_readiness.maximum_wind_gust_kph,
        station_readiness.minimum_visibility_km,
        station_readiness.low_visibility_observed,
        station_readiness.high_wind_observed,
        station_readiness.freezing_observed,
        station_readiness.forecast_count,
        station_readiness.average_temperature_error_c,
        station_readiness.average_precipitation_error_mm,
        station_readiness.average_wind_gust_error_kph,
        station_readiness.precipitation_miss_observed,
        station_readiness.alert_count,
        station_readiness.maximum_alert_severity_weight,
        station_readiness.maximum_weighted_impact_score,
        station_readiness.observed_incidents,
        station_readiness.active_subscription_count,
        station_readiness.active_api_calls_30d,
        station_readiness.regional_alert_opt_in_rate,
        station_readiness.active_sector_subscription_count,
        station_readiness.active_sector_api_calls_30d,
        station_readiness.weather_readiness_score,
        station_readiness.weather_readiness_band,
        station_readiness.region_service_context_key,
        station_readiness.service_context_band,
        station_readiness.airport_station_count,
        station_readiness.transport_station_count,
        station_readiness.transport_readiness_status
    from station_readiness

)

select * from final

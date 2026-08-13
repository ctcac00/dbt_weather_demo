with fct_station_weather_readiness as (

    select * from {{ ref('weather_foundation', 'fct_station_weather_readiness') }}

),

dim_region_service_context as (

    select * from {{ ref('weather_foundation', 'dim_region_service_context') }}

),

response_readiness as (

    select
        fct_station_weather_readiness.station_weather_readiness_key,
        fct_station_weather_readiness.station_daily_conditions_key,
        fct_station_weather_readiness.station_id,
        fct_station_weather_readiness.station_name,
        fct_station_weather_readiness.region,
        fct_station_weather_readiness.station_type,
        fct_station_weather_readiness.sector_focus,
        fct_station_weather_readiness.readiness_date,
        fct_station_weather_readiness.observation_count,
        fct_station_weather_readiness.precipitation_observed,
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
        fct_station_weather_readiness.affected_population_estimate,
        fct_station_weather_readiness.active_subscription_count,
        fct_station_weather_readiness.active_api_calls_30d,
        fct_station_weather_readiness.regional_alert_opt_in_rate,
        fct_station_weather_readiness.active_sector_subscription_count,
        fct_station_weather_readiness.active_sector_api_calls_30d,
        fct_station_weather_readiness.weather_readiness_score,
        fct_station_weather_readiness.weather_readiness_band,
        dim_region_service_context.region_service_context_key,
        dim_region_service_context.service_context_band,
        dim_region_service_context.alerted_station_count,
        dim_region_service_context.observed_incidents as regional_observed_incidents,
        dim_region_service_context.maximum_weighted_impact_score as regional_maximum_weighted_impact_score,
        case
            when fct_station_weather_readiness.maximum_alert_severity_weight >= 3
                or fct_station_weather_readiness.weather_readiness_score < 50
                or fct_station_weather_readiness.observed_incidents >= 20 then 'major_incident_ready'
            when fct_station_weather_readiness.maximum_alert_severity_weight >= 2
                or fct_station_weather_readiness.weather_readiness_score < 70
                or fct_station_weather_readiness.high_wind_observed
                or fct_station_weather_readiness.low_visibility_observed
                or fct_station_weather_readiness.freezing_observed then 'enhanced_monitoring'
            else 'standard_monitoring'
        end as resilience_response_tier
    from fct_station_weather_readiness
    inner join dim_region_service_context
        on fct_station_weather_readiness.region = dim_region_service_context.region

),

final as (

    select
        response_readiness.station_weather_readiness_key,
        response_readiness.station_daily_conditions_key,
        response_readiness.station_id,
        response_readiness.station_name,
        response_readiness.region,
        response_readiness.station_type,
        response_readiness.sector_focus,
        response_readiness.readiness_date,
        response_readiness.observation_count,
        response_readiness.precipitation_observed,
        response_readiness.low_visibility_observed,
        response_readiness.high_wind_observed,
        response_readiness.freezing_observed,
        response_readiness.forecast_count,
        response_readiness.average_temperature_error_c,
        response_readiness.average_precipitation_error_mm,
        response_readiness.average_wind_gust_error_kph,
        response_readiness.precipitation_miss_observed,
        response_readiness.alert_count,
        response_readiness.maximum_alert_severity_weight,
        response_readiness.maximum_weighted_impact_score,
        response_readiness.observed_incidents,
        response_readiness.affected_population_estimate,
        response_readiness.active_subscription_count,
        response_readiness.active_api_calls_30d,
        response_readiness.regional_alert_opt_in_rate,
        response_readiness.active_sector_subscription_count,
        response_readiness.active_sector_api_calls_30d,
        response_readiness.weather_readiness_score,
        response_readiness.weather_readiness_band,
        response_readiness.region_service_context_key,
        response_readiness.service_context_band,
        response_readiness.alerted_station_count,
        response_readiness.regional_observed_incidents,
        response_readiness.regional_maximum_weighted_impact_score,
        response_readiness.resilience_response_tier
    from response_readiness

)

select * from final

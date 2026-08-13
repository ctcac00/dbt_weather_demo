with resilience_response_readiness as (

    select * from {{ ref('resilience_response_readiness') }}

),

warning_response_readiness as (

    select
        resilience_response_readiness.readiness_date,
        resilience_response_readiness.region,
        resilience_response_readiness.resilience_response_tier,
        max(resilience_response_readiness.region_service_context_key) as region_service_context_key,
        max(resilience_response_readiness.service_context_band) as service_context_band,
        count(distinct resilience_response_readiness.station_id) as station_count,
        sum(resilience_response_readiness.observation_count) as observation_count,
        sum(resilience_response_readiness.forecast_count) as forecast_count,
        sum(resilience_response_readiness.alert_count) as alert_count,
        sum(resilience_response_readiness.observed_incidents) as observed_incidents,
        sum(resilience_response_readiness.affected_population_estimate) as affected_population_estimate,
        max(resilience_response_readiness.active_subscription_count) as active_subscription_count,
        max(resilience_response_readiness.active_api_calls_30d) as active_api_calls_30d,
        max(resilience_response_readiness.regional_alert_opt_in_rate) as regional_alert_opt_in_rate,
        sum(resilience_response_readiness.active_sector_subscription_count) as active_sector_subscription_count,
        sum(resilience_response_readiness.active_sector_api_calls_30d) as active_sector_api_calls_30d,
        avg(resilience_response_readiness.average_temperature_error_c) as average_temperature_error_c,
        avg(resilience_response_readiness.average_precipitation_error_mm) as average_precipitation_error_mm,
        avg(resilience_response_readiness.average_wind_gust_error_kph) as average_wind_gust_error_kph,
        count_if(resilience_response_readiness.precipitation_observed) as precipitation_station_count,
        count_if(resilience_response_readiness.low_visibility_observed) as low_visibility_station_count,
        count_if(resilience_response_readiness.high_wind_observed) as high_wind_station_count,
        count_if(resilience_response_readiness.freezing_observed) as freezing_station_count,
        avg(resilience_response_readiness.weather_readiness_score) as average_weather_readiness_score,
        min(resilience_response_readiness.weather_readiness_score) as minimum_weather_readiness_score,
        max(resilience_response_readiness.maximum_alert_severity_weight) as maximum_alert_severity_weight,
        max(resilience_response_readiness.maximum_weighted_impact_score) as maximum_weighted_impact_score,
        {{ safe_divide('sum(resilience_response_readiness.observed_incidents) * 100000', 'nullif(sum(resilience_response_readiness.affected_population_estimate), 0)') }} as incidents_per_100k_population,
        case
            when max(resilience_response_readiness.maximum_alert_severity_weight) >= 3
                or min(resilience_response_readiness.weather_readiness_score) < 50 then 'response_gap'
            when max(resilience_response_readiness.regional_alert_opt_in_rate) >= 0.75
                and max(resilience_response_readiness.active_subscription_count) >= 3 then 'response_ready'
            else 'watch_ready'
        end as warning_response_band
    from resilience_response_readiness
    group by
        resilience_response_readiness.readiness_date,
        resilience_response_readiness.region,
        resilience_response_readiness.resilience_response_tier

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['warning_response_readiness.readiness_date', 'warning_response_readiness.region', 'warning_response_readiness.resilience_response_tier']) }} as warning_response_readiness_key,
        warning_response_readiness.readiness_date,
        warning_response_readiness.region,
        warning_response_readiness.resilience_response_tier,
        warning_response_readiness.region_service_context_key,
        warning_response_readiness.service_context_band,
        warning_response_readiness.station_count,
        warning_response_readiness.observation_count,
        warning_response_readiness.forecast_count,
        warning_response_readiness.alert_count,
        warning_response_readiness.observed_incidents,
        warning_response_readiness.affected_population_estimate,
        warning_response_readiness.active_subscription_count,
        warning_response_readiness.active_api_calls_30d,
        warning_response_readiness.regional_alert_opt_in_rate,
        warning_response_readiness.active_sector_subscription_count,
        warning_response_readiness.active_sector_api_calls_30d,
        warning_response_readiness.average_temperature_error_c,
        warning_response_readiness.average_precipitation_error_mm,
        warning_response_readiness.average_wind_gust_error_kph,
        warning_response_readiness.precipitation_station_count,
        warning_response_readiness.low_visibility_station_count,
        warning_response_readiness.high_wind_station_count,
        warning_response_readiness.freezing_station_count,
        warning_response_readiness.average_weather_readiness_score,
        warning_response_readiness.minimum_weather_readiness_score,
        warning_response_readiness.maximum_alert_severity_weight,
        warning_response_readiness.maximum_weighted_impact_score,
        warning_response_readiness.incidents_per_100k_population,
        warning_response_readiness.warning_response_band
    from warning_response_readiness

)

select * from final

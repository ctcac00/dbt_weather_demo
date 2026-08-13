with data_service_weather_engagement as (

    select * from {{ ref('data_service_weather_engagement') }}

),

regional_engagement as (

    select
        data_service_weather_engagement.region,
        max(data_service_weather_engagement.region_service_context_key) as region_service_context_key,
        max(data_service_weather_engagement.service_context_band) as service_context_band,
        max(data_service_weather_engagement.highest_engagement_sector) as highest_engagement_sector,
        max(data_service_weather_engagement.supported_sector_count) as supported_sector_count,
        max(data_service_weather_engagement.subscribed_sector_count) as subscribed_sector_count,
        max(data_service_weather_engagement.active_subscription_count) as active_subscription_count,
        max(data_service_weather_engagement.active_api_calls_30d) as active_api_calls_30d,
        max(data_service_weather_engagement.alert_opt_in_rate) as alert_opt_in_rate,
        count(distinct data_service_weather_engagement.readiness_date) as readiness_day_count,
        sum(data_service_weather_engagement.station_day_count) as station_day_count,
        max(data_service_weather_engagement.station_count) as station_count,
        avg(data_service_weather_engagement.average_weather_readiness_score) as average_weather_readiness_score,
        sum(data_service_weather_engagement.constrained_station_day_count) as constrained_station_day_count,
        sum(data_service_weather_engagement.alert_count) as alert_count,
        sum(data_service_weather_engagement.forecast_count) as forecast_count,
        avg(data_service_weather_engagement.temperature_accuracy_rate) as temperature_accuracy_rate,
        avg(data_service_weather_engagement.precipitation_event_accuracy_rate) as precipitation_event_accuracy_rate,
        avg(data_service_weather_engagement.api_calls_per_active_subscription) as api_calls_per_active_subscription,
        case
            when avg(data_service_weather_engagement.average_weather_readiness_score) >= 85
                and max(data_service_weather_engagement.alert_opt_in_rate) >= 0.75 then 'high_engagement'
            when avg(data_service_weather_engagement.average_weather_readiness_score) >= 70
                and max(data_service_weather_engagement.active_subscription_count) >= 3 then 'moderate_engagement'
            else 'developing_engagement'
        end as weather_engagement_band
    from data_service_weather_engagement
    group by data_service_weather_engagement.region

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['regional_engagement.region']) }} as climate_data_service_engagement_key,
        current_date as metric_date,
        regional_engagement.region,
        regional_engagement.region_service_context_key,
        regional_engagement.service_context_band,
        regional_engagement.highest_engagement_sector,
        regional_engagement.supported_sector_count,
        regional_engagement.subscribed_sector_count,
        regional_engagement.active_subscription_count,
        regional_engagement.active_api_calls_30d,
        regional_engagement.alert_opt_in_rate,
        regional_engagement.readiness_day_count,
        regional_engagement.station_day_count,
        regional_engagement.station_count,
        regional_engagement.average_weather_readiness_score,
        regional_engagement.constrained_station_day_count,
        regional_engagement.alert_count,
        regional_engagement.forecast_count,
        regional_engagement.temperature_accuracy_rate,
        regional_engagement.precipitation_event_accuracy_rate,
        regional_engagement.api_calls_per_active_subscription,
        regional_engagement.weather_engagement_band
    from regional_engagement

)

select * from final

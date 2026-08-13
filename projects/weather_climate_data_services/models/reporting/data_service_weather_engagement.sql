with fct_service_subscription_activity as (

    select * from {{ ref('weather_foundation', 'fct_service_subscription_activity', v=1) }}

),

fct_station_weather_readiness as (

    select * from {{ ref('weather_foundation', 'fct_station_weather_readiness') }}

),

dim_region_service_context as (

    select * from {{ ref('weather_foundation', 'dim_region_service_context') }}

),

sector_subscription_rank as (

    select
        fct_service_subscription_activity.region,
        fct_service_subscription_activity.sector,
        sum(case when fct_service_subscription_activity.is_active_subscription then 1 else 0 end) as active_sector_subscription_count,
        sum(fct_service_subscription_activity.active_api_calls_30d) as active_sector_api_calls_30d,
        row_number() over (
            partition by fct_service_subscription_activity.region
            order by sum(fct_service_subscription_activity.active_api_calls_30d) desc, fct_service_subscription_activity.sector
        ) as sector_rank
    from fct_service_subscription_activity
    group by fct_service_subscription_activity.region, fct_service_subscription_activity.sector

),

daily_region_readiness as (

    select
        fct_station_weather_readiness.region,
        fct_station_weather_readiness.readiness_date,
        count(*) as station_day_count,
        count(distinct fct_station_weather_readiness.station_id) as station_count,
        avg(fct_station_weather_readiness.weather_readiness_score) as average_weather_readiness_score,
        count_if(fct_station_weather_readiness.weather_readiness_band in ('strained_readiness', 'critical_gap')) as constrained_station_day_count,
        sum(fct_station_weather_readiness.alert_count) as alert_count,
        sum(fct_station_weather_readiness.forecast_count) as forecast_count,
        avg(fct_station_weather_readiness.temperature_accuracy_rate) as temperature_accuracy_rate,
        avg(fct_station_weather_readiness.precipitation_event_accuracy_rate) as precipitation_event_accuracy_rate,
        max(fct_station_weather_readiness.active_subscription_count) as active_subscription_count,
        max(fct_station_weather_readiness.active_api_calls_30d) as active_api_calls_30d,
        max(fct_station_weather_readiness.regional_alert_opt_in_rate) as alert_opt_in_rate
    from fct_station_weather_readiness
    group by fct_station_weather_readiness.region, fct_station_weather_readiness.readiness_date

),

weather_engagement as (

    select
        {{ dbt_utils.generate_surrogate_key(['daily_region_readiness.region', 'daily_region_readiness.readiness_date']) }} as data_service_weather_engagement_key,
        daily_region_readiness.region,
        daily_region_readiness.readiness_date,
        daily_region_readiness.station_day_count,
        daily_region_readiness.station_count,
        daily_region_readiness.average_weather_readiness_score,
        daily_region_readiness.constrained_station_day_count,
        daily_region_readiness.alert_count,
        daily_region_readiness.forecast_count,
        daily_region_readiness.temperature_accuracy_rate,
        daily_region_readiness.precipitation_event_accuracy_rate,
        dim_region_service_context.region_service_context_key,
        dim_region_service_context.service_context_band,
        dim_region_service_context.supported_sector_count,
        dim_region_service_context.subscribed_sector_count,
        daily_region_readiness.active_subscription_count,
        daily_region_readiness.active_api_calls_30d,
        daily_region_readiness.alert_opt_in_rate,
        sector_subscription_rank.sector as highest_engagement_sector,
        coalesce(sector_subscription_rank.active_sector_subscription_count, 0) as highest_sector_active_subscription_count,
        coalesce(sector_subscription_rank.active_sector_api_calls_30d, 0) as highest_sector_api_calls_30d,
        {{ safe_divide('daily_region_readiness.active_api_calls_30d', 'nullif(daily_region_readiness.active_subscription_count, 0)') }} as api_calls_per_active_subscription,
        case
            when daily_region_readiness.average_weather_readiness_score >= 85
                and daily_region_readiness.alert_opt_in_rate >= 0.75 then 'high_engagement'
            when daily_region_readiness.average_weather_readiness_score >= 70
                and daily_region_readiness.active_subscription_count >= 3 then 'moderate_engagement'
            else 'developing_engagement'
        end as weather_engagement_band
    from daily_region_readiness
    inner join dim_region_service_context
        on daily_region_readiness.region = dim_region_service_context.region
    left join sector_subscription_rank
        on daily_region_readiness.region = sector_subscription_rank.region
        and sector_subscription_rank.sector_rank = 1

),

final as (

    select
        weather_engagement.data_service_weather_engagement_key,
        weather_engagement.region,
        weather_engagement.readiness_date,
        weather_engagement.station_day_count,
        weather_engagement.station_count,
        weather_engagement.average_weather_readiness_score,
        weather_engagement.constrained_station_day_count,
        weather_engagement.alert_count,
        weather_engagement.forecast_count,
        weather_engagement.temperature_accuracy_rate,
        weather_engagement.precipitation_event_accuracy_rate,
        weather_engagement.region_service_context_key,
        weather_engagement.service_context_band,
        weather_engagement.supported_sector_count,
        weather_engagement.subscribed_sector_count,
        weather_engagement.active_subscription_count,
        weather_engagement.active_api_calls_30d,
        weather_engagement.alert_opt_in_rate,
        weather_engagement.highest_engagement_sector,
        weather_engagement.highest_sector_active_subscription_count,
        weather_engagement.highest_sector_api_calls_30d,
        weather_engagement.api_calls_per_active_subscription,
        weather_engagement.weather_engagement_band
    from weather_engagement

)

select * from final

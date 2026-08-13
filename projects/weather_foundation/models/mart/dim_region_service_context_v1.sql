with dim_station as (

    select * from {{ ref('dim_station') }}

),

fct_service_subscription_activity as (

    select * from {{ ref('fct_service_subscription_activity') }}

),

fct_station_daily_conditions as (

    select * from {{ ref('fct_station_daily_conditions') }}

),

fct_forecast_accuracy as (

    select * from {{ ref('fct_forecast_accuracy') }}

),

fct_weather_alert_impact as (

    select * from {{ ref('fct_weather_alert_impact') }}

),

station_context as (

    select
        dim_station.region,
        count(*) as station_count,
        count_if(dim_station.is_active) as active_station_count,
        count(distinct dim_station.sector_focus) as supported_sector_count,
        count_if(dim_station.station_type = 'airport') as airport_station_count,
        count_if(dim_station.station_type = 'transport') as transport_station_count
    from dim_station
    group by dim_station.region

),

subscription_context as (

    select
        fct_service_subscription_activity.region,
        count(*) as total_subscription_count,
        sum(case when fct_service_subscription_activity.is_active_subscription then 1 else 0 end) as active_subscription_count,
        sum(case when fct_service_subscription_activity.is_trial_subscription then 1 else 0 end) as trial_subscription_count,
        count(distinct fct_service_subscription_activity.sector) as subscribed_sector_count,
        sum(fct_service_subscription_activity.active_monthly_fee_units) as active_monthly_fee_units,
        sum(fct_service_subscription_activity.active_api_calls_30d) as active_api_calls_30d,
        {{ safe_divide('sum(case when fct_service_subscription_activity.alert_opt_in then 1 else 0 end)', 'count(*)') }} as alert_opt_in_rate
    from fct_service_subscription_activity
    group by fct_service_subscription_activity.region

),

observed_context as (

    select
        fct_station_daily_conditions.region,
        count(*) as station_day_count,
        count(distinct fct_station_daily_conditions.station_id) as observed_station_count,
        min(fct_station_daily_conditions.observation_date) as first_observation_date,
        max(fct_station_daily_conditions.observation_date) as last_observation_date,
        sum(fct_station_daily_conditions.observation_count) as observation_count,
        sum(case when fct_station_daily_conditions.low_visibility_observed then 1 else 0 end) as low_visibility_station_day_count,
        sum(case when fct_station_daily_conditions.high_wind_observed then 1 else 0 end) as high_wind_station_day_count,
        sum(case when fct_station_daily_conditions.freezing_observed then 1 else 0 end) as freezing_station_day_count
    from fct_station_daily_conditions
    group by fct_station_daily_conditions.region

),

forecast_context as (

    select
        fct_forecast_accuracy.region,
        count(*) as forecast_count,
        count(distinct fct_forecast_accuracy.station_id) as forecast_station_count,
        avg(fct_forecast_accuracy.absolute_temperature_error_c) as average_temperature_error_c,
        avg(fct_forecast_accuracy.absolute_precipitation_error_mm) as average_precipitation_error_mm,
        avg(fct_forecast_accuracy.absolute_wind_gust_error_kph) as average_wind_gust_error_kph,
        avg(case when fct_forecast_accuracy.precipitation_event_correct then 1 else 0 end) as precipitation_event_accuracy_rate
    from fct_forecast_accuracy
    group by fct_forecast_accuracy.region

),

alert_context as (

    select
        fct_weather_alert_impact.region,
        count(*) as alert_count,
        count(distinct fct_weather_alert_impact.station_id) as alerted_station_count,
        sum(fct_weather_alert_impact.observed_incidents) as observed_incidents,
        sum(fct_weather_alert_impact.affected_population_estimate) as affected_population_estimate,
        avg(fct_weather_alert_impact.weighted_impact_score) as average_weighted_impact_score,
        max(fct_weather_alert_impact.weighted_impact_score) as maximum_weighted_impact_score
    from fct_weather_alert_impact
    group by fct_weather_alert_impact.region

),

region_service_context as (

    select
        {{ dbt_utils.generate_surrogate_key(['station_context.region']) }} as region_service_context_key,
        station_context.region,
        cast(station_context.station_count as number(18, 0)) as station_count,
        cast(station_context.active_station_count as number(18, 0)) as active_station_count,
        cast(station_context.supported_sector_count as number(18, 0)) as supported_sector_count,
        cast(station_context.airport_station_count as number(18, 0)) as airport_station_count,
        cast(station_context.transport_station_count as number(18, 0)) as transport_station_count,
        cast(coalesce(subscription_context.total_subscription_count, 0) as number(18, 0)) as total_subscription_count,
        cast(coalesce(subscription_context.active_subscription_count, 0) as number(18, 0)) as active_subscription_count,
        cast(coalesce(subscription_context.trial_subscription_count, 0) as number(18, 0)) as trial_subscription_count,
        cast(coalesce(subscription_context.subscribed_sector_count, 0) as number(18, 0)) as subscribed_sector_count,
        cast(coalesce(subscription_context.active_monthly_fee_units, 0) as number(18, 2)) as active_monthly_fee_units,
        cast(coalesce(subscription_context.active_api_calls_30d, 0) as number(18, 0)) as active_api_calls_30d,
        cast(coalesce(subscription_context.alert_opt_in_rate, 0) as float) as alert_opt_in_rate,
        cast(coalesce(observed_context.station_day_count, 0) as number(18, 0)) as station_day_count,
        cast(coalesce(observed_context.observed_station_count, 0) as number(18, 0)) as observed_station_count,
        observed_context.first_observation_date,
        observed_context.last_observation_date,
        cast(coalesce(observed_context.observation_count, 0) as number(18, 0)) as observation_count,
        cast(coalesce(observed_context.low_visibility_station_day_count, 0) as number(18, 0)) as low_visibility_station_day_count,
        cast(coalesce(observed_context.high_wind_station_day_count, 0) as number(18, 0)) as high_wind_station_day_count,
        cast(coalesce(observed_context.freezing_station_day_count, 0) as number(18, 0)) as freezing_station_day_count,
        cast(coalesce(forecast_context.forecast_count, 0) as number(18, 0)) as forecast_count,
        cast(coalesce(forecast_context.forecast_station_count, 0) as number(18, 0)) as forecast_station_count,
        coalesce(forecast_context.average_temperature_error_c, 0) as average_temperature_error_c,
        coalesce(forecast_context.average_precipitation_error_mm, 0) as average_precipitation_error_mm,
        coalesce(forecast_context.average_wind_gust_error_kph, 0) as average_wind_gust_error_kph,
        cast(coalesce(forecast_context.precipitation_event_accuracy_rate, 0) as float) as precipitation_event_accuracy_rate,
        cast(coalesce(alert_context.alert_count, 0) as number(18, 0)) as alert_count,
        cast(coalesce(alert_context.alerted_station_count, 0) as number(18, 0)) as alerted_station_count,
        cast(coalesce(alert_context.observed_incidents, 0) as number(18, 0)) as observed_incidents,
        cast(coalesce(alert_context.affected_population_estimate, 0) as number(18, 0)) as affected_population_estimate,
        coalesce(alert_context.average_weighted_impact_score, 0) as average_weighted_impact_score,
        coalesce(alert_context.maximum_weighted_impact_score, 0) as maximum_weighted_impact_score,
        case
            when coalesce(subscription_context.alert_opt_in_rate, 0) >= 0.75
                and coalesce(forecast_context.precipitation_event_accuracy_rate, 0) >= 0.75 then 'mature_service_context'
            when coalesce(subscription_context.active_subscription_count, 0) >= 3
                and coalesce(observed_context.observed_station_count, 0) >= station_context.active_station_count * 0.8 then 'scaling_service_context'
            else 'developing_service_context'
        end as service_context_band
    from station_context
    left join subscription_context
        on station_context.region = subscription_context.region
    left join observed_context
        on station_context.region = observed_context.region
    left join forecast_context
        on station_context.region = forecast_context.region
    left join alert_context
        on station_context.region = alert_context.region

),

final as (

    select
        region_service_context.region_service_context_key,
        region_service_context.region,
        region_service_context.station_count,
        region_service_context.active_station_count,
        region_service_context.supported_sector_count,
        region_service_context.airport_station_count,
        region_service_context.transport_station_count,
        region_service_context.total_subscription_count,
        region_service_context.active_subscription_count,
        region_service_context.trial_subscription_count,
        region_service_context.subscribed_sector_count,
        region_service_context.active_monthly_fee_units,
        region_service_context.active_api_calls_30d,
        region_service_context.alert_opt_in_rate,
        region_service_context.station_day_count,
        region_service_context.observed_station_count,
        region_service_context.first_observation_date,
        region_service_context.last_observation_date,
        region_service_context.observation_count,
        region_service_context.low_visibility_station_day_count,
        region_service_context.high_wind_station_day_count,
        region_service_context.freezing_station_day_count,
        region_service_context.forecast_count,
        region_service_context.forecast_station_count,
        region_service_context.average_temperature_error_c,
        region_service_context.average_precipitation_error_mm,
        region_service_context.average_wind_gust_error_kph,
        region_service_context.precipitation_event_accuracy_rate,
        region_service_context.alert_count,
        region_service_context.alerted_station_count,
        region_service_context.observed_incidents,
        region_service_context.affected_population_estimate,
        region_service_context.average_weighted_impact_score,
        region_service_context.maximum_weighted_impact_score,
        region_service_context.service_context_band
    from region_service_context

)

select * from final

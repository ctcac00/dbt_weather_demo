with fct_forecast_accuracy as (

    select * from {{ ref('fct_forecast_accuracy') }}

),

fct_weather_alert_impact as (

    select * from {{ ref('fct_weather_alert_impact') }}

),

fct_service_subscription_activity as (

    select * from {{ ref('fct_service_subscription_activity') }}

),

fct_station_daily_conditions as (

    select * from {{ ref('fct_station_daily_conditions') }}

),

dim_station as (

    select * from {{ ref('dim_station') }}

),

forecast_daily as (

    select
        fct_forecast_accuracy.station_id,
        fct_forecast_accuracy.forecast_valid_date as readiness_date,
        count(*) as forecast_count,
        avg(fct_forecast_accuracy.absolute_temperature_error_c) as average_temperature_error_c,
        avg(fct_forecast_accuracy.absolute_precipitation_error_mm) as average_precipitation_error_mm,
        avg(fct_forecast_accuracy.absolute_wind_gust_error_kph) as average_wind_gust_error_kph,
        avg(case when fct_forecast_accuracy.temperature_within_one_degree then 1 else 0 end) as temperature_accuracy_rate,
        avg(case when fct_forecast_accuracy.precipitation_event_correct then 1 else 0 end) as precipitation_event_accuracy_rate,
        max(case when not fct_forecast_accuracy.precipitation_event_correct then 1 else 0 end) = 1 as precipitation_miss_observed
    from fct_forecast_accuracy
    group by fct_forecast_accuracy.station_id, fct_forecast_accuracy.forecast_valid_date

),

alert_daily as (

    select
        fct_weather_alert_impact.station_id,
        cast(fct_weather_alert_impact.valid_from as date) as readiness_date,
        count(*) as alert_count,
        max(fct_weather_alert_impact.severity_weight) as maximum_alert_severity_weight,
        max(fct_weather_alert_impact.weighted_impact_score) as maximum_weighted_impact_score,
        sum(fct_weather_alert_impact.observed_incidents) as observed_incidents,
        sum(fct_weather_alert_impact.affected_population_estimate) as affected_population_estimate,
        avg(fct_weather_alert_impact.alert_opt_in_rate) as alert_opt_in_rate
    from fct_weather_alert_impact
    group by fct_weather_alert_impact.station_id, cast(fct_weather_alert_impact.valid_from as date)

),

regional_subscription_activity as (

    select
        fct_service_subscription_activity.region,
        count(*) as total_subscription_count,
        sum(case when fct_service_subscription_activity.is_active_subscription then 1 else 0 end) as active_subscription_count,
        sum(fct_service_subscription_activity.active_monthly_fee_units) as active_monthly_fee_units,
        sum(fct_service_subscription_activity.active_api_calls_30d) as active_api_calls_30d,
        {{ safe_divide('sum(case when fct_service_subscription_activity.alert_opt_in then 1 else 0 end)', 'count(*)') }} as regional_alert_opt_in_rate
    from fct_service_subscription_activity
    group by fct_service_subscription_activity.region

),

sector_subscription_activity as (

    select
        fct_service_subscription_activity.region,
        fct_service_subscription_activity.sector,
        sum(case when fct_service_subscription_activity.is_active_subscription then 1 else 0 end) as active_sector_subscription_count,
        sum(fct_service_subscription_activity.active_api_calls_30d) as active_sector_api_calls_30d
    from fct_service_subscription_activity
    group by fct_service_subscription_activity.region, fct_service_subscription_activity.sector

),

readiness_scored as (

    select
        fct_station_daily_conditions.station_daily_conditions_key,
        fct_station_daily_conditions.station_id,
        fct_station_daily_conditions.station_name,
        dim_station.station_key,
        fct_station_daily_conditions.region,
        fct_station_daily_conditions.station_type,
        fct_station_daily_conditions.sector_focus,
        fct_station_daily_conditions.observation_date as readiness_date,
        fct_station_daily_conditions.observation_count,
        fct_station_daily_conditions.average_temperature_c,
        fct_station_daily_conditions.total_precipitation_mm,
        fct_station_daily_conditions.maximum_wind_gust_kph,
        fct_station_daily_conditions.minimum_visibility_km,
        fct_station_daily_conditions.precipitation_observed,
        fct_station_daily_conditions.low_visibility_observed,
        fct_station_daily_conditions.high_wind_observed,
        fct_station_daily_conditions.freezing_observed,
        coalesce(forecast_daily.forecast_count, 0) as forecast_count,
        coalesce(forecast_daily.average_temperature_error_c, 0) as average_temperature_error_c,
        coalesce(forecast_daily.average_precipitation_error_mm, 0) as average_precipitation_error_mm,
        coalesce(forecast_daily.average_wind_gust_error_kph, 0) as average_wind_gust_error_kph,
        coalesce(forecast_daily.temperature_accuracy_rate, 0) as temperature_accuracy_rate,
        coalesce(forecast_daily.precipitation_event_accuracy_rate, 0) as precipitation_event_accuracy_rate,
        coalesce(forecast_daily.precipitation_miss_observed, false) as precipitation_miss_observed,
        coalesce(alert_daily.alert_count, 0) as alert_count,
        coalesce(alert_daily.maximum_alert_severity_weight, 0) as maximum_alert_severity_weight,
        coalesce(alert_daily.maximum_weighted_impact_score, 0) as maximum_weighted_impact_score,
        coalesce(alert_daily.observed_incidents, 0) as observed_incidents,
        coalesce(alert_daily.affected_population_estimate, 0) as affected_population_estimate,
        coalesce(regional_subscription_activity.total_subscription_count, 0) as total_subscription_count,
        coalesce(regional_subscription_activity.active_subscription_count, 0) as active_subscription_count,
        coalesce(regional_subscription_activity.active_monthly_fee_units, 0) as active_monthly_fee_units,
        coalesce(regional_subscription_activity.active_api_calls_30d, 0) as active_api_calls_30d,
        coalesce(regional_subscription_activity.regional_alert_opt_in_rate, 0) as regional_alert_opt_in_rate,
        coalesce(sector_subscription_activity.active_sector_subscription_count, 0) as active_sector_subscription_count,
        coalesce(sector_subscription_activity.active_sector_api_calls_30d, 0) as active_sector_api_calls_30d,
        case
            when fct_station_daily_conditions.low_visibility_observed then 15
            else 0
        end
        + case
            when fct_station_daily_conditions.high_wind_observed then 15
            else 0
        end
        + case
            when fct_station_daily_conditions.freezing_observed then 10
            else 0
        end
        + case
            when fct_station_daily_conditions.precipitation_observed then 5
            else 0
        end as observed_weather_penalty,
        case
            when coalesce(forecast_daily.average_wind_gust_error_kph, 0) >= 7 then 12
            when coalesce(forecast_daily.average_temperature_error_c, 0) > 1 then 6
            else 0
        end
        + case
            when coalesce(forecast_daily.precipitation_miss_observed, false) then 10
            else 0
        end as forecast_uncertainty_penalty,
        coalesce(alert_daily.maximum_alert_severity_weight, 0) * 8 as alert_impact_penalty,
        least(coalesce(regional_subscription_activity.active_api_calls_30d, 0) / 50000, 15)
        + least(coalesce(regional_subscription_activity.regional_alert_opt_in_rate, 0) * 10, 10)
        + least(coalesce(sector_subscription_activity.active_sector_api_calls_30d, 0) / 75000, 10) as service_engagement_credit
    from fct_station_daily_conditions
    inner join dim_station
        on fct_station_daily_conditions.station_id = dim_station.station_id
    left join forecast_daily
        on fct_station_daily_conditions.station_id = forecast_daily.station_id
        and fct_station_daily_conditions.observation_date = forecast_daily.readiness_date
    left join alert_daily
        on fct_station_daily_conditions.station_id = alert_daily.station_id
        and fct_station_daily_conditions.observation_date = alert_daily.readiness_date
    left join regional_subscription_activity
        on fct_station_daily_conditions.region = regional_subscription_activity.region
    left join sector_subscription_activity
        on fct_station_daily_conditions.region = sector_subscription_activity.region
        and fct_station_daily_conditions.sector_focus = sector_subscription_activity.sector

),

readiness_band as (

    select
        readiness_scored.station_daily_conditions_key,
        readiness_scored.station_key,
        readiness_scored.station_id,
        readiness_scored.station_name,
        readiness_scored.region,
        readiness_scored.station_type,
        readiness_scored.sector_focus,
        readiness_scored.readiness_date,
        cast(readiness_scored.observation_count as number(18, 0)) as observation_count,
        readiness_scored.average_temperature_c,
        readiness_scored.total_precipitation_mm,
        readiness_scored.maximum_wind_gust_kph,
        readiness_scored.minimum_visibility_km,
        readiness_scored.precipitation_observed,
        readiness_scored.low_visibility_observed,
        readiness_scored.high_wind_observed,
        readiness_scored.freezing_observed,
        cast(readiness_scored.forecast_count as number(18, 0)) as forecast_count,
        readiness_scored.average_temperature_error_c,
        readiness_scored.average_precipitation_error_mm,
        readiness_scored.average_wind_gust_error_kph,
        cast(readiness_scored.temperature_accuracy_rate as float) as temperature_accuracy_rate,
        cast(readiness_scored.precipitation_event_accuracy_rate as float) as precipitation_event_accuracy_rate,
        readiness_scored.precipitation_miss_observed,
        cast(readiness_scored.alert_count as number(18, 0)) as alert_count,
        readiness_scored.maximum_alert_severity_weight,
        readiness_scored.maximum_weighted_impact_score,
        cast(readiness_scored.observed_incidents as number(18, 0)) as observed_incidents,
        cast(readiness_scored.affected_population_estimate as number(18, 0)) as affected_population_estimate,
        cast(readiness_scored.total_subscription_count as number(18, 0)) as total_subscription_count,
        cast(readiness_scored.active_subscription_count as number(18, 0)) as active_subscription_count,
        cast(readiness_scored.active_monthly_fee_units as number(18, 2)) as active_monthly_fee_units,
        cast(readiness_scored.active_api_calls_30d as number(18, 0)) as active_api_calls_30d,
        cast(readiness_scored.regional_alert_opt_in_rate as float) as regional_alert_opt_in_rate,
        cast(readiness_scored.active_sector_subscription_count as number(18, 0)) as active_sector_subscription_count,
        cast(readiness_scored.active_sector_api_calls_30d as number(18, 0)) as active_sector_api_calls_30d,
        cast(greatest(
            0,
            least(
                100,
                100
                - readiness_scored.observed_weather_penalty
                - readiness_scored.forecast_uncertainty_penalty
                - readiness_scored.alert_impact_penalty
                + readiness_scored.service_engagement_credit
            )
        ) as float) as weather_readiness_score,
        case
            when greatest(0, least(
                100,
                100
                - readiness_scored.observed_weather_penalty
                - readiness_scored.forecast_uncertainty_penalty
                - readiness_scored.alert_impact_penalty
                + readiness_scored.service_engagement_credit
            )) >= 85 then 'ready'
            when greatest(0, least(
                100,
                100
                - readiness_scored.observed_weather_penalty
                - readiness_scored.forecast_uncertainty_penalty
                - readiness_scored.alert_impact_penalty
                + readiness_scored.service_engagement_credit
            )) >= 70 then 'enhanced_monitoring'
            when greatest(0, least(
                100,
                100
                - readiness_scored.observed_weather_penalty
                - readiness_scored.forecast_uncertainty_penalty
                - readiness_scored.alert_impact_penalty
                + readiness_scored.service_engagement_credit
            )) >= 50 then 'strained_readiness'
            else 'critical_gap'
        end as weather_readiness_band
    from readiness_scored

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['readiness_band.station_id', 'readiness_band.readiness_date']) }} as station_weather_readiness_key,
        readiness_band.station_daily_conditions_key,
        readiness_band.station_key,
        readiness_band.station_id,
        readiness_band.station_name,
        readiness_band.region,
        readiness_band.station_type,
        readiness_band.sector_focus,
        readiness_band.readiness_date,
        readiness_band.observation_count,
        readiness_band.average_temperature_c,
        readiness_band.total_precipitation_mm,
        readiness_band.maximum_wind_gust_kph,
        readiness_band.minimum_visibility_km,
        readiness_band.precipitation_observed,
        readiness_band.low_visibility_observed,
        readiness_band.high_wind_observed,
        readiness_band.freezing_observed,
        readiness_band.forecast_count,
        readiness_band.average_temperature_error_c,
        readiness_band.average_precipitation_error_mm,
        readiness_band.average_wind_gust_error_kph,
        readiness_band.temperature_accuracy_rate,
        readiness_band.precipitation_event_accuracy_rate,
        readiness_band.precipitation_miss_observed,
        readiness_band.alert_count,
        readiness_band.maximum_alert_severity_weight,
        readiness_band.maximum_weighted_impact_score,
        readiness_band.observed_incidents,
        readiness_band.affected_population_estimate,
        readiness_band.total_subscription_count,
        readiness_band.active_subscription_count,
        readiness_band.active_monthly_fee_units,
        readiness_band.active_api_calls_30d,
        readiness_band.regional_alert_opt_in_rate,
        readiness_band.active_sector_subscription_count,
        readiness_band.active_sector_api_calls_30d,
        readiness_band.weather_readiness_score,
        readiness_band.weather_readiness_band
    from readiness_band

)

select * from final

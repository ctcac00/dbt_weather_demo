with fct_forecast_accuracy as (

    select * from {{ ref('weather_foundation', 'fct_forecast_accuracy') }}

),

fct_weather_alert_impact as (

    select * from {{ ref('weather_foundation', 'fct_weather_alert_impact') }}

),

fct_station_daily_conditions as (

    select * from {{ ref('weather_foundation', 'fct_station_daily_conditions') }}

),

forecast_daily as (

    select
        fct_forecast_accuracy.station_id,
        fct_forecast_accuracy.forecast_valid_date as posture_date,
        avg(fct_forecast_accuracy.absolute_temperature_error_c) as average_temperature_error_c,
        avg(fct_forecast_accuracy.absolute_precipitation_error_mm) as average_precipitation_error_mm,
        avg(fct_forecast_accuracy.absolute_wind_gust_error_kph) as average_wind_gust_error_kph,
        max(case when not fct_forecast_accuracy.precipitation_event_correct then 1 else 0 end) = 1 as precipitation_miss_observed
    from fct_forecast_accuracy
    group by fct_forecast_accuracy.station_id, fct_forecast_accuracy.forecast_valid_date

),

alert_daily as (

    select
        fct_weather_alert_impact.station_id,
        cast(fct_weather_alert_impact.valid_from as date) as posture_date,
        count(*) as alert_count,
        max(fct_weather_alert_impact.severity_weight) as maximum_alert_severity_weight,
        max(fct_weather_alert_impact.weighted_impact_score) as maximum_weighted_impact_score,
        sum(fct_weather_alert_impact.observed_incidents) as observed_incidents
    from fct_weather_alert_impact
    group by fct_weather_alert_impact.station_id, cast(fct_weather_alert_impact.valid_from as date)

),

station_operating_posture as (

    select
        fct_station_daily_conditions.station_daily_conditions_key,
        fct_station_daily_conditions.station_id,
        fct_station_daily_conditions.station_name,
        fct_station_daily_conditions.region,
        fct_station_daily_conditions.station_type,
        fct_station_daily_conditions.sector_focus,
        case
            when fct_station_daily_conditions.sector_focus in ('aviation', 'rail', 'road') then fct_station_daily_conditions.sector_focus
            when fct_station_daily_conditions.station_type = 'airport' then 'aviation'
            when fct_station_daily_conditions.station_type = 'transport' then 'rail'
            else 'general_transport'
        end as operating_sector,
        fct_station_daily_conditions.observation_date as posture_date,
        fct_station_daily_conditions.observation_count,
        fct_station_daily_conditions.average_temperature_c,
        fct_station_daily_conditions.total_precipitation_mm,
        fct_station_daily_conditions.maximum_wind_gust_kph,
        fct_station_daily_conditions.minimum_visibility_km,
        fct_station_daily_conditions.low_visibility_observed,
        fct_station_daily_conditions.high_wind_observed,
        fct_station_daily_conditions.freezing_observed,
        coalesce(forecast_daily.average_temperature_error_c, 0) as average_temperature_error_c,
        coalesce(forecast_daily.average_precipitation_error_mm, 0) as average_precipitation_error_mm,
        coalesce(forecast_daily.average_wind_gust_error_kph, 0) as average_wind_gust_error_kph,
        coalesce(forecast_daily.precipitation_miss_observed, false) as precipitation_miss_observed,
        coalesce(alert_daily.alert_count, 0) as alert_count,
        coalesce(alert_daily.maximum_alert_severity_weight, 0) as maximum_alert_severity_weight,
        coalesce(alert_daily.maximum_weighted_impact_score, 0) as maximum_weighted_impact_score,
        coalesce(alert_daily.observed_incidents, 0) as observed_incidents,
        case
            when fct_station_daily_conditions.low_visibility_observed
                or fct_station_daily_conditions.high_wind_observed
                or fct_station_daily_conditions.freezing_observed then 2
            else 1
        end
        + case
            when forecast_daily.average_wind_gust_error_kph >= 7
                or forecast_daily.precipitation_miss_observed then 2
            when forecast_daily.average_temperature_error_c > 1 then 1
            else 0
        end
        + coalesce(alert_daily.maximum_alert_severity_weight, 0) as operating_posture_score
    from fct_station_daily_conditions
    left join forecast_daily
        on fct_station_daily_conditions.station_id = forecast_daily.station_id
        and fct_station_daily_conditions.observation_date = forecast_daily.posture_date
    left join alert_daily
        on fct_station_daily_conditions.station_id = alert_daily.station_id
        and fct_station_daily_conditions.observation_date = alert_daily.posture_date

),

final as (

    select
        station_operating_posture.station_daily_conditions_key,
        station_operating_posture.station_id,
        station_operating_posture.station_name,
        station_operating_posture.region,
        station_operating_posture.station_type,
        station_operating_posture.sector_focus,
        station_operating_posture.operating_sector,
        station_operating_posture.posture_date,
        station_operating_posture.observation_count,
        station_operating_posture.average_temperature_c,
        station_operating_posture.total_precipitation_mm,
        station_operating_posture.maximum_wind_gust_kph,
        station_operating_posture.minimum_visibility_km,
        station_operating_posture.low_visibility_observed,
        station_operating_posture.high_wind_observed,
        station_operating_posture.freezing_observed,
        station_operating_posture.average_temperature_error_c,
        station_operating_posture.average_precipitation_error_mm,
        station_operating_posture.average_wind_gust_error_kph,
        station_operating_posture.precipitation_miss_observed,
        station_operating_posture.alert_count,
        station_operating_posture.maximum_alert_severity_weight,
        station_operating_posture.maximum_weighted_impact_score,
        station_operating_posture.observed_incidents,
        station_operating_posture.operating_posture_score
    from station_operating_posture

)

select * from final

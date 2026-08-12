with forecast_daily as (
    select
        station_id,
        forecast_valid_date as posture_date,
        avg(absolute_temperature_error_c) as average_temperature_error_c,
        avg(absolute_precipitation_error_mm) as average_precipitation_error_mm,
        avg(absolute_wind_gust_error_kph) as average_wind_gust_error_kph,
        max(case when not precipitation_event_correct then 1 else 0 end) = 1 as precipitation_miss_observed
    from {{ ref('weather_foundation', 'fct_forecast_accuracy') }}
    group by station_id, forecast_valid_date
),

alert_daily as (
    select
        station_id,
        cast(valid_from as date) as posture_date,
        count(*) as alert_count,
        max(severity_weight) as maximum_alert_severity_weight,
        max(weighted_impact_score) as maximum_weighted_impact_score,
        sum(observed_incidents) as observed_incidents
    from {{ ref('weather_foundation', 'fct_weather_alert_impact') }}
    group by station_id, cast(valid_from as date)
)

select
    conditions.station_daily_conditions_key,
    conditions.station_id,
    conditions.station_name,
    conditions.region,
    conditions.station_type,
    conditions.sector_focus,
    case
        when conditions.sector_focus in ('aviation', 'rail', 'road') then conditions.sector_focus
        when conditions.station_type = 'airport' then 'aviation'
        when conditions.station_type = 'transport' then 'rail'
        else 'general_transport'
    end as operating_sector,
    conditions.observation_date as posture_date,
    conditions.observation_count,
    conditions.average_temperature_c,
    conditions.total_precipitation_mm,
    conditions.maximum_wind_gust_kph,
    conditions.minimum_visibility_km,
    conditions.low_visibility_observed,
    conditions.high_wind_observed,
    conditions.freezing_observed,
    coalesce(forecast_daily.average_temperature_error_c, 0) as average_temperature_error_c,
    coalesce(forecast_daily.average_precipitation_error_mm, 0) as average_precipitation_error_mm,
    coalesce(forecast_daily.average_wind_gust_error_kph, 0) as average_wind_gust_error_kph,
    coalesce(forecast_daily.precipitation_miss_observed, false) as precipitation_miss_observed,
    coalesce(alert_daily.alert_count, 0) as alert_count,
    coalesce(alert_daily.maximum_alert_severity_weight, 0) as maximum_alert_severity_weight,
    coalesce(alert_daily.maximum_weighted_impact_score, 0) as maximum_weighted_impact_score,
    coalesce(alert_daily.observed_incidents, 0) as observed_incidents,
    case
        when conditions.low_visibility_observed or conditions.high_wind_observed or conditions.freezing_observed then 2
        else 1
    end
    + case
        when forecast_daily.average_wind_gust_error_kph >= 7 or forecast_daily.precipitation_miss_observed then 2
        when forecast_daily.average_temperature_error_c > 1 then 1
        else 0
    end
    + coalesce(alert_daily.maximum_alert_severity_weight, 0) as operating_posture_score
from {{ ref('weather_foundation', 'fct_station_daily_conditions') }} as conditions
left join forecast_daily
    on conditions.station_id = forecast_daily.station_id
    and conditions.observation_date = forecast_daily.posture_date
left join alert_daily
    on conditions.station_id = alert_daily.station_id
    and conditions.observation_date = alert_daily.posture_date

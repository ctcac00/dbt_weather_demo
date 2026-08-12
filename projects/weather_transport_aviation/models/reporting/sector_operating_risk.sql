with forecast_risk as (
    select
        forecast.forecast_accuracy_key,
        forecast.station_id,
        forecast.region,
        forecast.station_type,
        forecast.sector_focus,
        forecast.forecast_valid_date,
        forecast.horizon_hours,
        forecast.absolute_temperature_error_c,
        forecast.absolute_precipitation_error_mm,
        forecast.absolute_wind_gust_error_kph,
        forecast.precipitation_event_correct,
        case
            when forecast.sector_focus in ('aviation', 'rail', 'road') then forecast.sector_focus
            when forecast.station_type = 'airport' then 'aviation'
            when forecast.station_type = 'transport' then 'rail'
            else 'general_transport'
        end as operating_sector,
        case
            when forecast.absolute_wind_gust_error_kph >= 7 or not forecast.precipitation_event_correct then 3
            when forecast.absolute_temperature_error_c > 1 then 2
            else 1
        end as forecast_uncertainty_score
    from {{ ref('weather_foundation', 'fct_forecast_accuracy') }} as forecast
),

alert_risk as (
    select
        station_id,
        cast(valid_from as date) as risk_date,
        max(severity_weight) as max_alert_severity_weight,
        max(weighted_impact_score) as max_weighted_impact_score
    from {{ ref('weather_foundation', 'fct_weather_alert_impact') }}
    where sector_focus in ('aviation', 'rail', 'road')
       or station_type in ('airport', 'transport')
    group by station_id, cast(valid_from as date)
)

select
    forecast_risk.forecast_accuracy_key,
    forecast_risk.station_id,
    forecast_risk.region,
    forecast_risk.station_type,
    forecast_risk.sector_focus,
    forecast_risk.operating_sector,
    forecast_risk.forecast_valid_date,
    forecast_risk.horizon_hours,
    forecast_risk.absolute_temperature_error_c,
    forecast_risk.absolute_precipitation_error_mm,
    forecast_risk.absolute_wind_gust_error_kph,
    forecast_risk.forecast_uncertainty_score,
    coalesce(alert_risk.max_alert_severity_weight, 0) as max_alert_severity_weight,
    coalesce(alert_risk.max_weighted_impact_score, 0) as max_weighted_impact_score,
    forecast_risk.forecast_uncertainty_score + coalesce(alert_risk.max_alert_severity_weight, 0) as operating_risk_score
from forecast_risk
left join alert_risk
    on forecast_risk.station_id = alert_risk.station_id
    and forecast_risk.forecast_valid_date = alert_risk.risk_date

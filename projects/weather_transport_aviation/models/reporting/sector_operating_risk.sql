with fct_forecast_accuracy as (

    select * from {{ ref('weather_foundation', 'fct_forecast_accuracy') }}

),

fct_weather_alert_impact as (

    select * from {{ ref('weather_foundation', 'fct_weather_alert_impact') }}

),

climate_data_service_adoption as (

    select * from {{ ref('weather_climate_data_services', 'climate_data_service_adoption') }}

),

forecast_risk as (

    select
        fct_forecast_accuracy.forecast_accuracy_key,
        fct_forecast_accuracy.station_id,
        fct_forecast_accuracy.region,
        fct_forecast_accuracy.station_type,
        fct_forecast_accuracy.sector_focus,
        fct_forecast_accuracy.forecast_valid_date,
        fct_forecast_accuracy.horizon_hours,
        fct_forecast_accuracy.absolute_temperature_error_c,
        fct_forecast_accuracy.absolute_precipitation_error_mm,
        fct_forecast_accuracy.absolute_wind_gust_error_kph,
        fct_forecast_accuracy.precipitation_event_correct,
        case
            when fct_forecast_accuracy.sector_focus in ('aviation', 'rail', 'road') then fct_forecast_accuracy.sector_focus
            when fct_forecast_accuracy.station_type = 'airport' then 'aviation'
            when fct_forecast_accuracy.station_type = 'transport' then 'rail'
            else 'general_transport'
        end as operating_sector,
        case
            when fct_forecast_accuracy.absolute_wind_gust_error_kph >= 7
                or not fct_forecast_accuracy.precipitation_event_correct then 3
            when fct_forecast_accuracy.absolute_temperature_error_c > 1 then 2
            else 1
        end as forecast_uncertainty_score
    from fct_forecast_accuracy

),

alert_risk as (

    select
        fct_weather_alert_impact.station_id,
        cast(fct_weather_alert_impact.valid_from as date) as risk_date,
        max(fct_weather_alert_impact.severity_weight) as max_alert_severity_weight,
        max(fct_weather_alert_impact.weighted_impact_score) as max_weighted_impact_score
    from fct_weather_alert_impact
    where fct_weather_alert_impact.sector_focus in ('aviation', 'rail', 'road')
        or fct_weather_alert_impact.station_type in ('airport', 'transport')
    group by fct_weather_alert_impact.station_id, cast(fct_weather_alert_impact.valid_from as date)

),

data_service_adoption as (

    select
        climate_data_service_adoption.region,
        climate_data_service_adoption.data_service_adoption_key,
        climate_data_service_adoption.active_subscription_count,
        climate_data_service_adoption.active_api_calls_30d,
        climate_data_service_adoption.alert_opt_in_rate,
        climate_data_service_adoption.adoption_band
    from climate_data_service_adoption

),

sector_operating_risk as (

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
        data_service_adoption.data_service_adoption_key,
        data_service_adoption.active_subscription_count,
        data_service_adoption.active_api_calls_30d,
        data_service_adoption.alert_opt_in_rate,
        data_service_adoption.adoption_band,
        coalesce(alert_risk.max_alert_severity_weight, 0) as max_alert_severity_weight,
        coalesce(alert_risk.max_weighted_impact_score, 0) as max_weighted_impact_score,
        forecast_risk.forecast_uncertainty_score + coalesce(alert_risk.max_alert_severity_weight, 0) as operating_risk_score
    from forecast_risk
    left join alert_risk
        on forecast_risk.station_id = alert_risk.station_id
        and forecast_risk.forecast_valid_date = alert_risk.risk_date
    left join data_service_adoption
        on forecast_risk.region = data_service_adoption.region

),

final as (

    select
        sector_operating_risk.forecast_accuracy_key,
        sector_operating_risk.station_id,
        sector_operating_risk.region,
        sector_operating_risk.station_type,
        sector_operating_risk.sector_focus,
        sector_operating_risk.operating_sector,
        sector_operating_risk.forecast_valid_date,
        sector_operating_risk.horizon_hours,
        sector_operating_risk.absolute_temperature_error_c,
        sector_operating_risk.absolute_precipitation_error_mm,
        sector_operating_risk.absolute_wind_gust_error_kph,
        sector_operating_risk.forecast_uncertainty_score,
        sector_operating_risk.data_service_adoption_key,
        sector_operating_risk.active_subscription_count,
        sector_operating_risk.active_api_calls_30d,
        sector_operating_risk.alert_opt_in_rate,
        sector_operating_risk.adoption_band,
        sector_operating_risk.max_alert_severity_weight,
        sector_operating_risk.max_weighted_impact_score,
        sector_operating_risk.operating_risk_score
    from sector_operating_risk

)

select * from final

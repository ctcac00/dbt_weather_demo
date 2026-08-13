with fct_weather_alert_impact as (

    select * from {{ ref('weather_foundation', 'fct_weather_alert_impact') }}

),

dim_station as (

    select * from {{ ref('weather_foundation', 'dim_station') }}

),

fct_forecast_accuracy as (

    select * from {{ ref('weather_foundation', 'fct_forecast_accuracy') }}

),

regional_adoption as (

    select
        fct_weather_alert_impact.region,
        max(fct_weather_alert_impact.active_subscription_count) as active_subscription_count,
        max(fct_weather_alert_impact.total_subscription_count) as total_subscription_count,
        max(fct_weather_alert_impact.active_monthly_fee_units) as active_monthly_fee_units,
        max(fct_weather_alert_impact.active_api_calls_30d) as active_api_calls_30d,
        max(fct_weather_alert_impact.alert_opt_in_rate) as alert_opt_in_rate,
        count(distinct fct_weather_alert_impact.alert_id) as alert_count,
        count(distinct dim_station.station_id) as station_count,
        avg(fct_forecast_accuracy.absolute_temperature_error_c) as average_temperature_error_c,
        avg(fct_forecast_accuracy.absolute_precipitation_error_mm) as average_precipitation_error_mm,
        {{ safe_divide('max(fct_weather_alert_impact.active_api_calls_30d)', 'nullif(max(fct_weather_alert_impact.active_subscription_count), 0)') }} as api_calls_per_active_subscription
    from fct_weather_alert_impact
    inner join dim_station
        on fct_weather_alert_impact.station_id = dim_station.station_id
    left join fct_forecast_accuracy
        on fct_weather_alert_impact.station_id = fct_forecast_accuracy.station_id
    group by fct_weather_alert_impact.region

),

final as (

    select
        regional_adoption.region,
        regional_adoption.active_subscription_count,
        regional_adoption.total_subscription_count,
        regional_adoption.active_monthly_fee_units,
        regional_adoption.active_api_calls_30d,
        regional_adoption.alert_opt_in_rate,
        regional_adoption.alert_count,
        regional_adoption.station_count,
        regional_adoption.average_temperature_error_c,
        regional_adoption.average_precipitation_error_mm,
        regional_adoption.api_calls_per_active_subscription
    from regional_adoption

)

select * from final

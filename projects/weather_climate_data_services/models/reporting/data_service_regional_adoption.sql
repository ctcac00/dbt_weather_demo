select
    alert.region,
    max(alert.active_subscription_count) as active_subscription_count,
    max(alert.total_subscription_count) as total_subscription_count,
    max(alert.active_monthly_fee_units) as active_monthly_fee_units,
    max(alert.active_api_calls_30d) as active_api_calls_30d,
    max(alert.alert_opt_in_rate) as alert_opt_in_rate,
    count(distinct alert.alert_id) as alert_count,
    count(distinct station.station_id) as station_count,
    avg(forecast.absolute_temperature_error_c) as average_temperature_error_c,
    avg(forecast.absolute_precipitation_error_mm) as average_precipitation_error_mm,
    {{ safe_divide('max(alert.active_api_calls_30d)', 'nullif(max(alert.active_subscription_count), 0)') }} as api_calls_per_active_subscription
from {{ ref('weather_foundation', 'fct_weather_alert_impact') }} as alert
inner join {{ ref('weather_foundation', 'dim_station') }} as station
    on alert.station_id = station.station_id
left join {{ ref('weather_foundation', 'fct_forecast_accuracy') }} as forecast
    on alert.station_id = forecast.station_id
group by alert.region

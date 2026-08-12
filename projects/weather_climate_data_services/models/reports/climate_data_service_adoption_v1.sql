select
    {{ dbt_utils.generate_surrogate_key(['region']) }} as data_service_adoption_key,
    region,
    active_subscription_count,
    total_subscription_count,
    active_monthly_fee_units,
    active_api_calls_30d,
    alert_opt_in_rate,
    alert_count,
    station_count,
    average_temperature_error_c,
    average_precipitation_error_mm,
    cast(api_calls_per_active_subscription as float) as api_calls_per_active_subscription,
    case
        when alert_opt_in_rate >= 0.8 and active_api_calls_30d >= 150000 then 'high_adoption'
        when alert_opt_in_rate >= 0.5 then 'moderate_adoption'
        else 'developing_adoption'
    end as adoption_band
from {{ ref('data_service_regional_adoption') }}

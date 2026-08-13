select
    sector,
    customer_segment,
    region,
    count(*) as subscription_count,
    count_if(is_active_subscription) as active_subscription_count,
    count_if(is_trial_subscription) as trial_subscription_count,
    sum(monthly_fee_units) as monthly_fee_units,
    sum(active_monthly_fee_units) as active_monthly_fee_units,
    sum(api_calls_30d) as api_calls_30d,
    sum(active_api_calls_30d) as active_api_calls_30d,
    {{ safe_divide('sum(case when alert_opt_in then 1 else 0 end)', 'count(*)') }} as alert_opt_in_rate,
    {{ safe_divide('sum(active_api_calls_30d)', 'nullif(count_if(is_active_subscription), 0)') }} as api_calls_per_active_subscription
from {{ ref('weather_foundation', 'fct_service_subscription_activity', v=1) }}
group by sector, customer_segment, region

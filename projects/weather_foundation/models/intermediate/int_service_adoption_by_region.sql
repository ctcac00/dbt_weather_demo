select
    region,
    count_if(status = 'active') as active_subscription_count,
    count(*) as total_subscription_count,
    sum(case when status = 'active' then monthly_fee_units else 0 end) as active_monthly_fee_units,
    sum(case when status = 'active' then api_calls_30d else 0 end) as active_api_calls_30d,
    {{ safe_divide("sum(case when alert_opt_in then 1 else 0 end)", "count(*)") }} as alert_opt_in_rate
from {{ ref('stg_service_subscriptions') }}
group by region

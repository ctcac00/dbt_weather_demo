select
    cast(subscription_id as varchar) as subscription_id,
    cast(customer_segment as varchar) as customer_segment,
    cast(sector as varchar) as sector,
    cast(region as varchar) as region,
    cast(service_tier as varchar) as service_tier,
    cast(started_at as date) as started_at,
    cast(status as varchar) as status,
    cast(monthly_fee_units as number(12, 2)) as monthly_fee_units,
    cast(api_calls_30d as number(18, 0)) as api_calls_30d,
    cast(alert_opt_in as boolean) as alert_opt_in
from {{ ref('raw_service_subscriptions') }}

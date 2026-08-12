select
    {{ dbt_utils.generate_surrogate_key(['subscription_id']) }} as subscription_activity_key,
    subscription_id,
    customer_segment,
    sector,
    region,
    service_tier,
    started_at,
    status,
    status = 'active' as is_active_subscription,
    status = 'trial' as is_trial_subscription,
    cast(monthly_fee_units as number(12, 2)) as monthly_fee_units,
    cast(api_calls_30d as number(18, 0)) as api_calls_30d,
    alert_opt_in,
    cast(case
        when status = 'active' then monthly_fee_units
        else 0
    end as number(12, 2)) as active_monthly_fee_units,
    cast(case
        when status = 'active' then api_calls_30d
        else 0
    end as number(18, 0)) as active_api_calls_30d
from {{ ref('stg_service_subscriptions') }}

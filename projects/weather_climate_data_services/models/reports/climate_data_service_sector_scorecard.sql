select
    {{ dbt_utils.generate_surrogate_key(['sector', 'customer_segment', 'region']) }} as sector_scorecard_key,
    sector,
    customer_segment,
    region,
    subscription_count,
    active_subscription_count,
    trial_subscription_count,
    monthly_fee_units,
    active_monthly_fee_units,
    active_api_calls_30d,
    alert_opt_in_rate,
    api_calls_per_active_subscription,
    case
        when alert_opt_in_rate >= 0.8 and active_api_calls_30d >= 150000 then 'high_engagement'
        when alert_opt_in_rate >= 0.5 or active_subscription_count >= 2 then 'steady_engagement'
        else 'developing_engagement'
    end as service_engagement_band
from {{ ref('data_service_sector_scorecard') }}

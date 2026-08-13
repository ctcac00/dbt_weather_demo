with fct_service_subscription_activity as (

    select * from {{ ref('weather_foundation', 'fct_service_subscription_activity', v=1) }}

),

sector_scorecard as (

    select
        fct_service_subscription_activity.sector,
        fct_service_subscription_activity.customer_segment,
        fct_service_subscription_activity.region,
        count(*) as subscription_count,
        count_if(fct_service_subscription_activity.is_active_subscription) as active_subscription_count,
        count_if(fct_service_subscription_activity.is_trial_subscription) as trial_subscription_count,
        sum(fct_service_subscription_activity.monthly_fee_units) as monthly_fee_units,
        sum(fct_service_subscription_activity.active_monthly_fee_units) as active_monthly_fee_units,
        sum(fct_service_subscription_activity.api_calls_30d) as api_calls_30d,
        sum(fct_service_subscription_activity.active_api_calls_30d) as active_api_calls_30d,
        {{ safe_divide('sum(case when fct_service_subscription_activity.alert_opt_in then 1 else 0 end)', 'count(*)') }} as alert_opt_in_rate,
        {{ safe_divide('sum(fct_service_subscription_activity.active_api_calls_30d)', 'nullif(count_if(fct_service_subscription_activity.is_active_subscription), 0)') }} as api_calls_per_active_subscription
    from fct_service_subscription_activity
    group by
        fct_service_subscription_activity.sector,
        fct_service_subscription_activity.customer_segment,
        fct_service_subscription_activity.region

),

final as (

    select
        sector_scorecard.sector,
        sector_scorecard.customer_segment,
        sector_scorecard.region,
        sector_scorecard.subscription_count,
        sector_scorecard.active_subscription_count,
        sector_scorecard.trial_subscription_count,
        sector_scorecard.monthly_fee_units,
        sector_scorecard.active_monthly_fee_units,
        sector_scorecard.api_calls_30d,
        sector_scorecard.active_api_calls_30d,
        sector_scorecard.alert_opt_in_rate,
        sector_scorecard.api_calls_per_active_subscription
    from sector_scorecard

)

select * from final

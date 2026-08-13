with stg_service_subscriptions as (

    select * from {{ ref('stg_service_subscriptions') }}

),

subscription_activity as (

    select
        {{ dbt_utils.generate_surrogate_key(['stg_service_subscriptions.subscription_id']) }} as subscription_activity_key,
        stg_service_subscriptions.subscription_id,
        stg_service_subscriptions.customer_segment,
        stg_service_subscriptions.sector,
        stg_service_subscriptions.region,
        stg_service_subscriptions.service_tier,
        stg_service_subscriptions.started_at,
        stg_service_subscriptions.status,
        stg_service_subscriptions.status = 'active' as is_active_subscription,
        stg_service_subscriptions.status = 'trial' as is_trial_subscription,
        cast(stg_service_subscriptions.monthly_fee_units as number(12, 2)) as monthly_fee_units,
        cast(stg_service_subscriptions.api_calls_30d as number(18, 0)) as api_calls_30d,
        stg_service_subscriptions.alert_opt_in,
        cast(case
            when stg_service_subscriptions.status = 'active' then stg_service_subscriptions.monthly_fee_units
            else 0
        end as number(12, 2)) as active_monthly_fee_units,
        cast(case
            when stg_service_subscriptions.status = 'active' then stg_service_subscriptions.api_calls_30d
            else 0
        end as number(18, 0)) as active_api_calls_30d
    from stg_service_subscriptions

),

final as (

    select
        subscription_activity.subscription_activity_key,
        subscription_activity.subscription_id,
        subscription_activity.customer_segment,
        subscription_activity.sector,
        subscription_activity.region,
        subscription_activity.service_tier,
        subscription_activity.started_at,
        subscription_activity.status,
        subscription_activity.is_active_subscription,
        subscription_activity.is_trial_subscription,
        subscription_activity.monthly_fee_units,
        subscription_activity.api_calls_30d,
        subscription_activity.alert_opt_in,
        subscription_activity.active_monthly_fee_units,
        subscription_activity.active_api_calls_30d
    from subscription_activity

)

select * from final

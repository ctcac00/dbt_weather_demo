with stg_service_subscriptions as (

    select * from {{ ref('stg_service_subscriptions') }}

),

regional_adoption as (

    select
        stg_service_subscriptions.region,
        count_if(stg_service_subscriptions.status = 'active') as active_subscription_count,
        count(*) as total_subscription_count,
        sum(case when stg_service_subscriptions.status = 'active' then stg_service_subscriptions.monthly_fee_units else 0 end) as active_monthly_fee_units,
        sum(case when stg_service_subscriptions.status = 'active' then stg_service_subscriptions.api_calls_30d else 0 end) as active_api_calls_30d,
        {{ safe_divide("sum(case when stg_service_subscriptions.alert_opt_in then 1 else 0 end)", "count(*)") }} as alert_opt_in_rate
    from stg_service_subscriptions
    group by stg_service_subscriptions.region

),

final as (

    select
        regional_adoption.region,
        regional_adoption.active_subscription_count,
        regional_adoption.total_subscription_count,
        regional_adoption.active_monthly_fee_units,
        regional_adoption.active_api_calls_30d,
        regional_adoption.alert_opt_in_rate
    from regional_adoption

)

select * from final

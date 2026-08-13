with raw_service_subscriptions as (

    select * from {{ ref('raw_service_subscriptions') }}

),

final as (

    select
        cast(raw_service_subscriptions.subscription_id as varchar) as subscription_id,
        cast(raw_service_subscriptions.customer_segment as varchar) as customer_segment,
        cast(raw_service_subscriptions.sector as varchar) as sector,
        cast(raw_service_subscriptions.region as varchar) as region,
        cast(raw_service_subscriptions.service_tier as varchar) as service_tier,
        cast(raw_service_subscriptions.started_at as date) as started_at,
        cast(raw_service_subscriptions.status as varchar) as status,
        cast(raw_service_subscriptions.monthly_fee_units as number(12, 2)) as monthly_fee_units,
        cast(raw_service_subscriptions.api_calls_30d as number(18, 0)) as api_calls_30d,
        cast(raw_service_subscriptions.alert_opt_in as boolean) as alert_opt_in
    from raw_service_subscriptions

)

select * from final

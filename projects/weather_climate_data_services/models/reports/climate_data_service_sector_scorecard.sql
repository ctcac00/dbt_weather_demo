with data_service_sector_scorecard as (

    select * from {{ ref('data_service_sector_scorecard') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['data_service_sector_scorecard.sector', 'data_service_sector_scorecard.customer_segment', 'data_service_sector_scorecard.region']) }} as sector_scorecard_key,
        current_date as metric_date,
        data_service_sector_scorecard.sector,
        data_service_sector_scorecard.customer_segment,
        data_service_sector_scorecard.region,
        data_service_sector_scorecard.subscription_count,
        data_service_sector_scorecard.active_subscription_count,
        data_service_sector_scorecard.trial_subscription_count,
        data_service_sector_scorecard.monthly_fee_units,
        data_service_sector_scorecard.active_monthly_fee_units,
        data_service_sector_scorecard.active_api_calls_30d,
        data_service_sector_scorecard.alert_opt_in_rate,
        data_service_sector_scorecard.api_calls_per_active_subscription,
        case
            when data_service_sector_scorecard.alert_opt_in_rate >= 0.8
                and data_service_sector_scorecard.active_api_calls_30d >= 150000 then 'high_engagement'
            when data_service_sector_scorecard.alert_opt_in_rate >= 0.5
                or data_service_sector_scorecard.active_subscription_count >= 2 then 'steady_engagement'
            else 'developing_engagement'
        end as service_engagement_band
    from data_service_sector_scorecard

)

select * from final

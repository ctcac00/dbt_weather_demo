with data_service_regional_adoption as (

    select * from {{ ref('data_service_regional_adoption') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['data_service_regional_adoption.region']) }} as data_service_adoption_key,
        current_date as metric_date,
        data_service_regional_adoption.region,
        data_service_regional_adoption.active_subscription_count,
        data_service_regional_adoption.total_subscription_count,
        data_service_regional_adoption.active_monthly_fee_units,
        data_service_regional_adoption.active_api_calls_30d,
        data_service_regional_adoption.alert_opt_in_rate,
        data_service_regional_adoption.alert_count,
        data_service_regional_adoption.station_count,
        data_service_regional_adoption.average_temperature_error_c,
        data_service_regional_adoption.average_precipitation_error_mm,
        cast(data_service_regional_adoption.api_calls_per_active_subscription as float) as api_calls_per_active_subscription,
        case
            when data_service_regional_adoption.alert_opt_in_rate >= 0.8
                and data_service_regional_adoption.active_api_calls_30d >= 150000 then 'high_adoption'
            when data_service_regional_adoption.alert_opt_in_rate >= 0.5 then 'moderate_adoption'
            else 'developing_adoption'
        end as adoption_band
    from data_service_regional_adoption

)

select * from final

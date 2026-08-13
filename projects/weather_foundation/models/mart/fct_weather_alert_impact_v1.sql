with int_alerts_enriched as (

    select * from {{ ref('int_alerts_enriched') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['int_alerts_enriched.alert_id']) }} as alert_impact_key,
        int_alerts_enriched.alert_id,
        int_alerts_enriched.station_id,
        int_alerts_enriched.station_name,
        int_alerts_enriched.region,
        int_alerts_enriched.station_type,
        int_alerts_enriched.sector_focus,
        int_alerts_enriched.issued_at,
        int_alerts_enriched.valid_from,
        int_alerts_enriched.valid_to,
        int_alerts_enriched.alert_duration_hours,
        int_alerts_enriched.severity,
        int_alerts_enriched.alert_type,
        int_alerts_enriched.status,
        int_alerts_enriched.expected_impact_score,
        int_alerts_enriched.observed_incidents,
        int_alerts_enriched.affected_population_estimate,
        cast(int_alerts_enriched.incidents_per_100k_population as float) as incidents_per_100k_population,
        int_alerts_enriched.active_subscription_count,
        int_alerts_enriched.total_subscription_count,
        int_alerts_enriched.active_monthly_fee_units,
        int_alerts_enriched.active_api_calls_30d,
        cast(int_alerts_enriched.alert_opt_in_rate as float) as alert_opt_in_rate,
        int_alerts_enriched.severity_weight,
        int_alerts_enriched.expected_impact_score * int_alerts_enriched.severity_weight as weighted_impact_score
    from int_alerts_enriched

)

select * from final

with warning_station_alerts as (

    select * from {{ ref('warning_station_alerts') }}

),

warning_coverage as (

    select
        warning_station_alerts.region,
        warning_station_alerts.alert_type,
        warning_station_alerts.severity,
        max(warning_station_alerts.data_service_adoption_key) as data_service_adoption_key,
        count(*) as alert_count,
        count(distinct warning_station_alerts.station_id) as station_count,
        max(warning_station_alerts.active_subscription_count) as active_subscription_count,
        max(warning_station_alerts.active_api_calls_30d) as active_api_calls_30d,
        max(warning_station_alerts.alert_opt_in_rate) as alert_opt_in_rate,
        max(warning_station_alerts.adoption_band) as adoption_band,
        sum(warning_station_alerts.observed_incidents) as observed_incidents,
        sum(warning_station_alerts.affected_population_estimate) as affected_population_estimate,
        avg(warning_station_alerts.expected_impact_score) as average_expected_impact_score,
        avg(warning_station_alerts.weighted_impact_score) as average_weighted_impact_score,
        max(warning_station_alerts.resilience_response_tier) as highest_response_tier,
        {{ safe_divide('sum(warning_station_alerts.observed_incidents) * 100000', 'sum(warning_station_alerts.affected_population_estimate)') }} as incidents_per_100k_population
    from warning_station_alerts
    group by current_date, warning_station_alerts.region, warning_station_alerts.alert_type, warning_station_alerts.severity

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['warning_coverage.region', 'warning_coverage.alert_type', 'warning_coverage.severity']) }} as warning_coverage_key,
        current_date as metric_date,
        warning_coverage.region,
        warning_coverage.alert_type,
        warning_coverage.severity,
        warning_coverage.data_service_adoption_key,
        warning_coverage.alert_count,
        warning_coverage.station_count,
        warning_coverage.active_subscription_count,
        warning_coverage.active_api_calls_30d,
        warning_coverage.alert_opt_in_rate,
        warning_coverage.adoption_band,
        warning_coverage.observed_incidents,
        warning_coverage.affected_population_estimate,
        warning_coverage.average_expected_impact_score,
        warning_coverage.average_weighted_impact_score,
        warning_coverage.highest_response_tier,
        warning_coverage.incidents_per_100k_population
    from warning_coverage

)

select * from final

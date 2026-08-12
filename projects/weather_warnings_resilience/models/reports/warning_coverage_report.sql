select
    {{ dbt_utils.generate_surrogate_key(['region', 'alert_type', 'severity']) }} as warning_coverage_key,
    current_date as metric_date,
    region,
    alert_type,
    severity,
    max(data_service_adoption_key) as data_service_adoption_key,
    count(*) as alert_count,
    count(distinct station_id) as station_count,
    max(active_subscription_count) as active_subscription_count,
    max(active_api_calls_30d) as active_api_calls_30d,
    max(alert_opt_in_rate) as alert_opt_in_rate,
    max(adoption_band) as adoption_band,
    sum(observed_incidents) as observed_incidents,
    sum(affected_population_estimate) as affected_population_estimate,
    avg(expected_impact_score) as average_expected_impact_score,
    avg(weighted_impact_score) as average_weighted_impact_score,
    max(resilience_response_tier) as highest_response_tier,
    {{ safe_divide('sum(observed_incidents) * 100000', 'sum(affected_population_estimate)') }} as incidents_per_100k_population
from {{ ref('warning_station_alerts') }}
group by current_date, region, alert_type, severity

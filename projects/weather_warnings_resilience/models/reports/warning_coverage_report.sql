select
    {{ dbt_utils.generate_surrogate_key(['region', 'alert_type', 'severity']) }} as warning_coverage_key,
    region,
    alert_type,
    severity,
    count(*) as alert_count,
    count(distinct station_id) as station_count,
    sum(observed_incidents) as observed_incidents,
    sum(affected_population_estimate) as affected_population_estimate,
    avg(expected_impact_score) as average_expected_impact_score,
    avg(weighted_impact_score) as average_weighted_impact_score,
    max(resilience_response_tier) as highest_response_tier,
    {{ safe_divide('sum(observed_incidents) * 100000', 'sum(affected_population_estimate)') }} as incidents_per_100k_population
from {{ ref('warning_station_alerts') }}
group by region, alert_type, severity

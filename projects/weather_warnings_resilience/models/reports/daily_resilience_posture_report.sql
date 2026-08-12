select
    {{ dbt_utils.generate_surrogate_key(['posture_date', 'region']) }} as daily_resilience_posture_key,
    posture_date,
    region,
    count(distinct station_id) as station_count,
    sum(observation_count) as observation_count,
    count_if(precipitation_observed) as precipitation_station_count,
    count_if(low_visibility_observed) as low_visibility_station_count,
    count_if(high_wind_observed) as high_wind_station_count,
    count_if(freezing_observed) as freezing_station_count,
    sum(alert_count) as alert_count,
    sum(observed_incidents) as observed_incidents,
    sum(affected_population_estimate) as affected_population_estimate,
    avg(average_expected_impact_score) as average_expected_impact_score,
    avg(average_weighted_impact_score) as average_weighted_impact_score,
    max(maximum_weighted_impact_score) as maximum_weighted_impact_score,
    max(resilience_posture) as highest_resilience_posture,
    {{ safe_divide('sum(observed_incidents) * 100000', 'sum(affected_population_estimate)') }} as incidents_per_100k_population
from {{ ref('daily_resilience_station_posture') }}
group by posture_date, region

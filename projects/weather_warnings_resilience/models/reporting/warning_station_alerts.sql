select
    alert.alert_impact_key,
    alert.alert_id,
    station.station_key,
    alert.station_id,
    station.station_name,
    station.region,
    station.station_type,
    station.sector_focus,
    alert.issued_at,
    alert.valid_from,
    alert.valid_to,
    alert.alert_duration_hours,
    alert.severity,
    alert.alert_type,
    alert.status,
    alert.expected_impact_score,
    alert.observed_incidents,
    alert.affected_population_estimate,
    alert.incidents_per_100k_population,
    alert.active_subscription_count,
    alert.alert_opt_in_rate,
    alert.weighted_impact_score,
    case
        when alert.severity = 'red' or alert.weighted_impact_score >= 180 then 'major_incident_ready'
        when alert.severity = 'amber' or alert.weighted_impact_score >= 100 then 'enhanced_monitoring'
        else 'standard_monitoring'
    end as resilience_response_tier
from {{ ref('weather_foundation', 'fct_weather_alert_impact') }} as alert
inner join {{ ref('weather_foundation', 'dim_station') }} as station
    on alert.station_id = station.station_id

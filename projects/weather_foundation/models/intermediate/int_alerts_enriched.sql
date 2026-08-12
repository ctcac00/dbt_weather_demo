select
    alerts.alert_id,
    alerts.station_id,
    stations.station_name,
    alerts.region,
    stations.station_type,
    stations.sector_focus,
    alerts.issued_at,
    alerts.valid_from,
    alerts.valid_to,
    datediff('hour', alerts.valid_from, alerts.valid_to) as alert_duration_hours,
    alerts.severity,
    alerts.alert_type,
    alerts.status,
    alerts.expected_impact_score,
    alerts.observed_incidents,
    alerts.affected_population_estimate,
    {{ safe_divide('alerts.observed_incidents * 100000', 'alerts.affected_population_estimate') }} as incidents_per_100k_population,
    coalesce(adoption.active_subscription_count, 0) as active_subscription_count,
    coalesce(adoption.total_subscription_count, 0) as total_subscription_count,
    coalesce(adoption.active_monthly_fee_units, 0) as active_monthly_fee_units,
    coalesce(adoption.active_api_calls_30d, 0) as active_api_calls_30d,
    cast(coalesce(adoption.alert_opt_in_rate, 0.0) as float) as alert_opt_in_rate,
    case
        when alerts.severity = 'red' then 3
        when alerts.severity = 'amber' then 2
        else 1
    end as severity_weight
from {{ ref('stg_weather_alerts') }} as alerts
inner join {{ ref('stg_stations') }} as stations
    on alerts.station_id = stations.station_id
left join {{ ref('int_service_adoption_by_region') }} as adoption
    on alerts.region = adoption.region

select
    cast(alert_id as varchar) as alert_id,
    cast(station_id as varchar) as station_id,
    cast(region as varchar) as region,
    cast(issued_at as timestamp_ntz) as issued_at,
    cast(valid_from as timestamp_ntz) as valid_from,
    cast(valid_to as timestamp_ntz) as valid_to,
    cast(severity as varchar) as severity,
    cast(alert_type as varchar) as alert_type,
    cast(status as varchar) as status,
    cast(expected_impact_score as float) as expected_impact_score,
    cast(observed_incidents as number(10, 0)) as observed_incidents,
    cast(affected_population_estimate as number(18, 0)) as affected_population_estimate
from {{ ref('raw_weather_alerts') }}

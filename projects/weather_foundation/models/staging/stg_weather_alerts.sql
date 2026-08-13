with raw_weather_alerts as (

    select * from {{ ref('raw_weather_alerts') }}

),

final as (

    select
        cast(raw_weather_alerts.alert_id as varchar) as alert_id,
        cast(raw_weather_alerts.station_id as varchar) as station_id,
        cast(raw_weather_alerts.region as varchar) as region,
        cast(raw_weather_alerts.issued_at as timestamp_ntz) as issued_at,
        cast(raw_weather_alerts.valid_from as timestamp_ntz) as valid_from,
        cast(raw_weather_alerts.valid_to as timestamp_ntz) as valid_to,
        cast(raw_weather_alerts.severity as varchar) as severity,
        cast(raw_weather_alerts.alert_type as varchar) as alert_type,
        cast(raw_weather_alerts.status as varchar) as status,
        cast(raw_weather_alerts.expected_impact_score as float) as expected_impact_score,
        cast(raw_weather_alerts.observed_incidents as number(10, 0)) as observed_incidents,
        cast(raw_weather_alerts.affected_population_estimate as number(18, 0)) as affected_population_estimate
    from raw_weather_alerts

)

select * from final

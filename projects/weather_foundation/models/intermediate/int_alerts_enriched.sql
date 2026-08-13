with stg_weather_alerts as (

    select * from {{ ref('stg_weather_alerts') }}

),

stg_stations as (

    select * from {{ ref('stg_stations') }}

),

int_service_adoption_by_region as (

    select * from {{ ref('int_service_adoption_by_region') }}

),

alerts_enriched as (

    select
        stg_weather_alerts.alert_id,
        stg_weather_alerts.station_id,
        stg_stations.station_name,
        stg_weather_alerts.region,
        stg_stations.station_type,
        stg_stations.sector_focus,
        stg_weather_alerts.issued_at,
        stg_weather_alerts.valid_from,
        stg_weather_alerts.valid_to,
        datediff('hour', stg_weather_alerts.valid_from, stg_weather_alerts.valid_to) as alert_duration_hours,
        stg_weather_alerts.severity,
        stg_weather_alerts.alert_type,
        stg_weather_alerts.status,
        stg_weather_alerts.expected_impact_score,
        stg_weather_alerts.observed_incidents,
        stg_weather_alerts.affected_population_estimate,
        {{ safe_divide('stg_weather_alerts.observed_incidents * 100000', 'stg_weather_alerts.affected_population_estimate') }} as incidents_per_100k_population,
        coalesce(int_service_adoption_by_region.active_subscription_count, 0) as active_subscription_count,
        coalesce(int_service_adoption_by_region.total_subscription_count, 0) as total_subscription_count,
        coalesce(int_service_adoption_by_region.active_monthly_fee_units, 0) as active_monthly_fee_units,
        coalesce(int_service_adoption_by_region.active_api_calls_30d, 0) as active_api_calls_30d,
        cast(coalesce(int_service_adoption_by_region.alert_opt_in_rate, 0.0) as float) as alert_opt_in_rate,
        case
            when stg_weather_alerts.severity = 'red' then 3
            when stg_weather_alerts.severity = 'amber' then 2
            else 1
        end as severity_weight
    from stg_weather_alerts
    inner join stg_stations
        on stg_weather_alerts.station_id = stg_stations.station_id
    left join int_service_adoption_by_region
        on stg_weather_alerts.region = int_service_adoption_by_region.region

),

final as (

    select
        alerts_enriched.alert_id,
        alerts_enriched.station_id,
        alerts_enriched.station_name,
        alerts_enriched.region,
        alerts_enriched.station_type,
        alerts_enriched.sector_focus,
        alerts_enriched.issued_at,
        alerts_enriched.valid_from,
        alerts_enriched.valid_to,
        alerts_enriched.alert_duration_hours,
        alerts_enriched.severity,
        alerts_enriched.alert_type,
        alerts_enriched.status,
        alerts_enriched.expected_impact_score,
        alerts_enriched.observed_incidents,
        alerts_enriched.affected_population_estimate,
        alerts_enriched.incidents_per_100k_population,
        alerts_enriched.active_subscription_count,
        alerts_enriched.total_subscription_count,
        alerts_enriched.active_monthly_fee_units,
        alerts_enriched.active_api_calls_30d,
        alerts_enriched.alert_opt_in_rate,
        alerts_enriched.severity_weight
    from alerts_enriched

)

select * from final

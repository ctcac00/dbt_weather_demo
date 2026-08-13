with fct_weather_alert_impact as (

    select * from {{ ref('weather_foundation', 'fct_weather_alert_impact') }}

),

dim_station as (

    select * from {{ ref('weather_foundation', 'dim_station') }}

),

climate_data_service_adoption as (

    select * from {{ ref('weather_climate_data_services', 'climate_data_service_adoption') }}

),

data_service_adoption as (

    select
        climate_data_service_adoption.region,
        climate_data_service_adoption.data_service_adoption_key,
        climate_data_service_adoption.active_subscription_count,
        climate_data_service_adoption.active_api_calls_30d,
        climate_data_service_adoption.alert_opt_in_rate,
        climate_data_service_adoption.adoption_band
    from climate_data_service_adoption

),

station_alerts as (

    select
        fct_weather_alert_impact.alert_impact_key,
        fct_weather_alert_impact.alert_id,
        dim_station.station_key,
        fct_weather_alert_impact.station_id,
        dim_station.station_name,
        dim_station.region,
        dim_station.station_type,
        dim_station.sector_focus,
        fct_weather_alert_impact.issued_at,
        fct_weather_alert_impact.valid_from,
        fct_weather_alert_impact.valid_to,
        fct_weather_alert_impact.alert_duration_hours,
        fct_weather_alert_impact.severity,
        fct_weather_alert_impact.alert_type,
        fct_weather_alert_impact.status,
        fct_weather_alert_impact.expected_impact_score,
        fct_weather_alert_impact.observed_incidents,
        fct_weather_alert_impact.affected_population_estimate,
        fct_weather_alert_impact.incidents_per_100k_population,
        data_service_adoption.data_service_adoption_key,
        data_service_adoption.active_subscription_count,
        data_service_adoption.active_api_calls_30d,
        data_service_adoption.alert_opt_in_rate,
        data_service_adoption.adoption_band,
        fct_weather_alert_impact.weighted_impact_score,
        case
            when fct_weather_alert_impact.severity = 'red'
                or fct_weather_alert_impact.weighted_impact_score >= 180 then 'major_incident_ready'
            when fct_weather_alert_impact.severity = 'amber'
                or fct_weather_alert_impact.weighted_impact_score >= 100 then 'enhanced_monitoring'
            else 'standard_monitoring'
        end as resilience_response_tier
    from fct_weather_alert_impact
    inner join dim_station
        on fct_weather_alert_impact.station_id = dim_station.station_id
    left join data_service_adoption
        on dim_station.region = data_service_adoption.region

),

final as (

    select
        station_alerts.alert_impact_key,
        station_alerts.alert_id,
        station_alerts.station_key,
        station_alerts.station_id,
        station_alerts.station_name,
        station_alerts.region,
        station_alerts.station_type,
        station_alerts.sector_focus,
        station_alerts.issued_at,
        station_alerts.valid_from,
        station_alerts.valid_to,
        station_alerts.alert_duration_hours,
        station_alerts.severity,
        station_alerts.alert_type,
        station_alerts.status,
        station_alerts.expected_impact_score,
        station_alerts.observed_incidents,
        station_alerts.affected_population_estimate,
        station_alerts.incidents_per_100k_population,
        station_alerts.data_service_adoption_key,
        station_alerts.active_subscription_count,
        station_alerts.active_api_calls_30d,
        station_alerts.alert_opt_in_rate,
        station_alerts.adoption_band,
        station_alerts.weighted_impact_score,
        station_alerts.resilience_response_tier
    from station_alerts

)

select * from final

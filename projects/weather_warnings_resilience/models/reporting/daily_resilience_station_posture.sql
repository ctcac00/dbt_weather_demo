with alert_daily as (
    select
        station_id,
        cast(valid_from as date) as posture_date,
        region,
        count(*) as alert_count,
        sum(observed_incidents) as observed_incidents,
        sum(affected_population_estimate) as affected_population_estimate,
        avg(expected_impact_score) as average_expected_impact_score,
        avg(weighted_impact_score) as average_weighted_impact_score,
        max(weighted_impact_score) as maximum_weighted_impact_score
    from {{ ref('weather_foundation', 'fct_weather_alert_impact') }}
    group by station_id, cast(valid_from as date), region
)

select
    conditions.station_daily_conditions_key,
    conditions.station_id,
    conditions.station_name,
    conditions.region,
    conditions.station_type,
    conditions.sector_focus,
    conditions.observation_date as posture_date,
    conditions.observation_count,
    conditions.total_precipitation_mm,
    conditions.maximum_wind_gust_kph,
    conditions.minimum_visibility_km,
    conditions.precipitation_observed,
    conditions.low_visibility_observed,
    conditions.high_wind_observed,
    conditions.freezing_observed,
    coalesce(alert_daily.alert_count, 0) as alert_count,
    coalesce(alert_daily.observed_incidents, 0) as observed_incidents,
    coalesce(alert_daily.affected_population_estimate, 0) as affected_population_estimate,
    coalesce(alert_daily.average_expected_impact_score, 0) as average_expected_impact_score,
    coalesce(alert_daily.average_weighted_impact_score, 0) as average_weighted_impact_score,
    coalesce(alert_daily.maximum_weighted_impact_score, 0) as maximum_weighted_impact_score,
    case
        when alert_daily.maximum_weighted_impact_score >= 180
            or coalesce(alert_daily.observed_incidents, 0) >= 20 then 'major_incident_ready'
        when alert_daily.maximum_weighted_impact_score >= 100
            or conditions.low_visibility_observed
            or conditions.high_wind_observed
            or conditions.freezing_observed then 'enhanced_monitoring'
        else 'standard_monitoring'
    end as resilience_posture
from {{ ref('weather_foundation', 'fct_station_daily_conditions') }} as conditions
left join alert_daily
    on conditions.station_id = alert_daily.station_id
    and conditions.observation_date = alert_daily.posture_date

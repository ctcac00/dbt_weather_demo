with fct_weather_alert_impact as (

    select * from {{ ref('weather_foundation', 'fct_weather_alert_impact') }}

),

fct_station_daily_conditions as (

    select * from {{ ref('weather_foundation', 'fct_station_daily_conditions') }}

),

alert_daily as (

    select
        fct_weather_alert_impact.station_id,
        cast(fct_weather_alert_impact.valid_from as date) as posture_date,
        fct_weather_alert_impact.region,
        count(*) as alert_count,
        sum(fct_weather_alert_impact.observed_incidents) as observed_incidents,
        sum(fct_weather_alert_impact.affected_population_estimate) as affected_population_estimate,
        avg(fct_weather_alert_impact.expected_impact_score) as average_expected_impact_score,
        avg(fct_weather_alert_impact.weighted_impact_score) as average_weighted_impact_score,
        max(fct_weather_alert_impact.weighted_impact_score) as maximum_weighted_impact_score
    from fct_weather_alert_impact
    group by fct_weather_alert_impact.station_id, cast(fct_weather_alert_impact.valid_from as date), fct_weather_alert_impact.region

),

resilience_station_posture as (

    select
        fct_station_daily_conditions.station_daily_conditions_key,
        fct_station_daily_conditions.station_id,
        fct_station_daily_conditions.station_name,
        fct_station_daily_conditions.region,
        fct_station_daily_conditions.station_type,
        fct_station_daily_conditions.sector_focus,
        fct_station_daily_conditions.observation_date as posture_date,
        fct_station_daily_conditions.observation_count,
        fct_station_daily_conditions.total_precipitation_mm,
        fct_station_daily_conditions.maximum_wind_gust_kph,
        fct_station_daily_conditions.minimum_visibility_km,
        fct_station_daily_conditions.precipitation_observed,
        fct_station_daily_conditions.low_visibility_observed,
        fct_station_daily_conditions.high_wind_observed,
        fct_station_daily_conditions.freezing_observed,
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
                or fct_station_daily_conditions.low_visibility_observed
                or fct_station_daily_conditions.high_wind_observed
                or fct_station_daily_conditions.freezing_observed then 'enhanced_monitoring'
            else 'standard_monitoring'
        end as resilience_posture
    from fct_station_daily_conditions
    left join alert_daily
        on fct_station_daily_conditions.station_id = alert_daily.station_id
        and fct_station_daily_conditions.observation_date = alert_daily.posture_date

),

final as (

    select
        resilience_station_posture.station_daily_conditions_key,
        resilience_station_posture.station_id,
        resilience_station_posture.station_name,
        resilience_station_posture.region,
        resilience_station_posture.station_type,
        resilience_station_posture.sector_focus,
        resilience_station_posture.posture_date,
        resilience_station_posture.observation_count,
        resilience_station_posture.total_precipitation_mm,
        resilience_station_posture.maximum_wind_gust_kph,
        resilience_station_posture.minimum_visibility_km,
        resilience_station_posture.precipitation_observed,
        resilience_station_posture.low_visibility_observed,
        resilience_station_posture.high_wind_observed,
        resilience_station_posture.freezing_observed,
        resilience_station_posture.alert_count,
        resilience_station_posture.observed_incidents,
        resilience_station_posture.affected_population_estimate,
        resilience_station_posture.average_expected_impact_score,
        resilience_station_posture.average_weighted_impact_score,
        resilience_station_posture.maximum_weighted_impact_score,
        resilience_station_posture.resilience_posture
    from resilience_station_posture

)

select * from final

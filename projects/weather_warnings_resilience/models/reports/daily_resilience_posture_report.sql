with daily_resilience_station_posture as (

    select * from {{ ref('daily_resilience_station_posture') }}

),

daily_resilience_posture as (

    select
        daily_resilience_station_posture.posture_date,
        daily_resilience_station_posture.region,
        count(distinct daily_resilience_station_posture.station_id) as station_count,
        sum(daily_resilience_station_posture.observation_count) as observation_count,
        count_if(daily_resilience_station_posture.precipitation_observed) as precipitation_station_count,
        count_if(daily_resilience_station_posture.low_visibility_observed) as low_visibility_station_count,
        count_if(daily_resilience_station_posture.high_wind_observed) as high_wind_station_count,
        count_if(daily_resilience_station_posture.freezing_observed) as freezing_station_count,
        sum(daily_resilience_station_posture.alert_count) as alert_count,
        sum(daily_resilience_station_posture.observed_incidents) as observed_incidents,
        sum(daily_resilience_station_posture.affected_population_estimate) as affected_population_estimate,
        avg(daily_resilience_station_posture.average_expected_impact_score) as average_expected_impact_score,
        avg(daily_resilience_station_posture.average_weighted_impact_score) as average_weighted_impact_score,
        max(daily_resilience_station_posture.maximum_weighted_impact_score) as maximum_weighted_impact_score,
        max(daily_resilience_station_posture.resilience_posture) as highest_resilience_posture,
        {{ safe_divide('sum(daily_resilience_station_posture.observed_incidents) * 100000', 'sum(daily_resilience_station_posture.affected_population_estimate)') }} as incidents_per_100k_population
    from daily_resilience_station_posture
    group by daily_resilience_station_posture.posture_date, daily_resilience_station_posture.region

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['daily_resilience_posture.posture_date', 'daily_resilience_posture.region']) }} as daily_resilience_posture_key,
        daily_resilience_posture.posture_date,
        daily_resilience_posture.region,
        daily_resilience_posture.station_count,
        daily_resilience_posture.observation_count,
        daily_resilience_posture.precipitation_station_count,
        daily_resilience_posture.low_visibility_station_count,
        daily_resilience_posture.high_wind_station_count,
        daily_resilience_posture.freezing_station_count,
        daily_resilience_posture.alert_count,
        daily_resilience_posture.observed_incidents,
        daily_resilience_posture.affected_population_estimate,
        daily_resilience_posture.average_expected_impact_score,
        daily_resilience_posture.average_weighted_impact_score,
        daily_resilience_posture.maximum_weighted_impact_score,
        daily_resilience_posture.highest_resilience_posture,
        daily_resilience_posture.incidents_per_100k_population
    from daily_resilience_posture

)

select * from final

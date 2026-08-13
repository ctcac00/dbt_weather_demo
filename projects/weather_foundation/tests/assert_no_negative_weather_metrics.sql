with fct_weather_alert_impact as (

    select * from {{ ref('fct_weather_alert_impact') }}

),

fct_forecast_accuracy as (

    select * from {{ ref('fct_forecast_accuracy') }}

),

negative_alert_metrics as (

    select
        'fct_weather_alert_impact' as model_name,
        fct_weather_alert_impact.alert_id as record_id,
        'negative impact metric' as failure_reason
    from fct_weather_alert_impact
    where fct_weather_alert_impact.observed_incidents < 0
        or fct_weather_alert_impact.affected_population_estimate < 0
        or fct_weather_alert_impact.active_subscription_count < 0
        or fct_weather_alert_impact.active_monthly_fee_units < 0
        or fct_weather_alert_impact.expected_impact_score < 0
        or fct_weather_alert_impact.weighted_impact_score < 0

),

negative_forecast_metrics as (

    select
        'fct_forecast_accuracy' as model_name,
        fct_forecast_accuracy.forecast_id as record_id,
        'negative precipitation metric' as failure_reason
    from fct_forecast_accuracy
    where fct_forecast_accuracy.forecast_precipitation_mm < 0
        or fct_forecast_accuracy.observed_precipitation_mm < 0
        or fct_forecast_accuracy.absolute_precipitation_error_mm < 0

),

unioned as (

    select * from negative_alert_metrics

    union all

    select * from negative_forecast_metrics

),

final as (

    select
        unioned.model_name,
        unioned.record_id,
        unioned.failure_reason
    from unioned

)

select * from final

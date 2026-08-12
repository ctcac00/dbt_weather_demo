select
    'fct_weather_alert_impact' as model_name,
    alert_id as record_id,
    'negative impact metric' as failure_reason
from {{ ref('fct_weather_alert_impact') }}
where observed_incidents < 0
   or affected_population_estimate < 0
   or active_subscription_count < 0
   or active_monthly_fee_units < 0
   or expected_impact_score < 0
   or weighted_impact_score < 0

union all

select
    'fct_forecast_accuracy' as model_name,
    forecast_id as record_id,
    'negative precipitation metric' as failure_reason
from {{ ref('fct_forecast_accuracy') }}
where forecast_precipitation_mm < 0
   or observed_precipitation_mm < 0
   or absolute_precipitation_error_mm < 0

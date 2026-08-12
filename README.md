# Generic Weather Company dbt Mesh Demo

This repository is a Snowflake-targeted dbt Mesh demo for a fictional weather organization. It uses generic weather-service concepts only: stations, observations, forecasts, alerts, subscriptions, resilience reporting, transport/aviation risk, and climate/data-service adoption.

## Projects

- `projects/weather_foundation` is the producer project. It owns fictional seeds, staging models, intermediate enrichment, and public contracted marts.
- `projects/weather_warnings_resilience` consumes only public foundation marts and publishes a warning coverage report.
- `projects/weather_transport_aviation` consumes only public foundation marts and publishes a sector operating risk report.
- `projects/weather_climate_data_services` consumes only public foundation marts and publishes a data-service adoption report.

Domain projects depend on `weather_foundation` through `dependencies.yml` and use two-argument refs such as `{{ ref('weather_foundation', 'fct_weather_alert_impact') }}`.

## Public Foundation Interface

- `dim_station` version `1`: public station dimension with an enforced contract.
- `fct_forecast_accuracy` version `1`: public incremental forecast accuracy fact with an enforced contract.
- `fct_weather_alert_impact` version `1`: public alert impact and regional service adoption fact with an enforced contract.

## Documentation and Tests

Every seed and model declares `config.meta.primary_key` in YAML. Each primary key column is documented and covered by `not_null` and `unique` tests, with additional relationship, accepted-value, and range tests on critical dimensions and metrics.

## Local Setup

```bash
cp profiles.yml ~/.dbt/profiles.yml
# Fill in the Snowflake placeholders in ~/.dbt/profiles.yml

cd projects/weather_foundation
dbt deps
dbt seed
dbt build
```

Build the foundation project first, then run the same `dbt deps` and `dbt build` workflow in each domain project after the public producer artifacts are available to the mesh.

## Validation Commands

Use parse and compile during development; reserve materializing commands for validation.

```bash
cd projects/weather_foundation && dbt deps && dbt parse && dbt compile
cd ../weather_warnings_resilience && dbt deps && dbt parse && dbt compile
cd ../weather_transport_aviation && dbt deps && dbt parse && dbt compile
cd ../weather_climate_data_services && dbt deps && dbt parse && dbt compile
```

## Terraform

The `terraform/` directory provisions dbt platform resources for the four projects and assumes Snowflake infrastructure already exists. Fill in placeholders for the dbt platform account, access URL including `/api`, service token, GitHub App installation details, Snowflake connection metadata, and Snowflake key-pair credential values.

## dbt Concepts Covered

- dbt Mesh producer/consumer split with project dependencies and cross-project refs.
- Public model contracts, groups, versions, and column `data_type` declarations.
- Seeds, staging, intermediate, mart, and reporting layers.
- `dbt_utils`, `dbt_expectations`, custom macros, incremental models, generic tests, and a singular test.

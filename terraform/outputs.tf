output "dbt_cloud_project_ids" {
  description = "dbt platform project IDs by project name."
  value = {
    weather_foundation            = module.weather_foundation.project_id
    weather_climate_data_services = module.weather_climate_data_services.project_id
    weather_warnings_resilience   = module.weather_warnings_resilience.project_id
    weather_transport_aviation    = module.weather_transport_aviation.project_id
  }
}

output "dbt_cloud_production_environment_ids" {
  description = "Production environment IDs by project name."
  value = {
    weather_foundation            = module.weather_foundation.production_environment_id
    weather_climate_data_services = module.weather_climate_data_services.production_environment_id
    weather_warnings_resilience   = module.weather_warnings_resilience.production_environment_id
    weather_transport_aviation    = module.weather_transport_aviation.production_environment_id
  }
}

output "dbt_cloud_production_merge_build_job_ids" {
  description = "Production merge-triggered dbt build job IDs by project name."
  value = {
    weather_foundation            = module.weather_foundation.production_merge_build_job_id
    weather_climate_data_services = module.weather_climate_data_services.production_merge_build_job_id
    weather_warnings_resilience   = module.weather_warnings_resilience.production_merge_build_job_id
    weather_transport_aviation    = module.weather_transport_aviation.production_merge_build_job_id
  }
}

output "dbt_cloud_project_ids" {
  description = "dbt platform project IDs by project name."
  value = {
    for project_name, project in module.dbt_cloud_projects : project_name => project.project_id
  }
}

output "dbt_cloud_production_environment_ids" {
  description = "Production environment IDs by project name."
  value = {
    for project_name, project in module.dbt_cloud_projects : project_name => project.production_environment_id
  }
}

output "project_id" {
  description = "dbt Cloud project ID."
  value       = dbtcloud_project.this.id
}

output "repository_id" {
  description = "dbt Cloud repository ID linking this project to the monorepo subdirectory."
  value       = dbtcloud_repository.this.repository_id
}

output "development_environment_id" {
  description = "dbt Cloud Development environment ID."
  value       = dbtcloud_environment.development.environment_id
}

output "production_environment_id" {
  description = "dbt Cloud Production environment ID."
  value       = dbtcloud_environment.production.environment_id
}

output "ci_environment_id" {
  description = "dbt Cloud CI environment ID."
  value       = dbtcloud_environment.ci.environment_id
}

output "production_credential_id" {
  description = "dbt Cloud Snowflake production credential ID."
  value       = dbtcloud_snowflake_credential.production.credential_id
}

output "ci_credential_id" {
  description = "dbt Cloud Snowflake CI credential ID."
  value       = dbtcloud_snowflake_credential.ci.credential_id
}

output "daily_production_build_job_id" {
  description = "Production dbt build job ID, if enabled."
  value       = try(dbtcloud_job.daily_production_build[0].job_id, null)
}

output "slim_ci_job_id" {
  description = "Slim CI job ID, if enabled."
  value       = try(dbtcloud_job.slim_ci[0].id, null)
}

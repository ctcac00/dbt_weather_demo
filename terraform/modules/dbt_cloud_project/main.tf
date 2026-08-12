terraform {
  required_providers {
    dbtcloud = {
      source = "dbt-labs/dbtcloud"
    }
  }
}

resource "dbtcloud_project" "this" {
  name                     = var.project_name
  dbt_project_subdirectory = var.project_subdirectory
}

resource "dbtcloud_repository" "this" {
  project_id             = dbtcloud_project.this.id
  remote_url             = var.git_remote_url
  git_clone_strategy     = var.git_clone_strategy
  github_installation_id = var.github_installation_id
}

# See references/adapters.md for the full adapter-specific credential fields
# (auth type, user/token/private key, etc.) beyond environment routing.
resource "dbtcloud_snowflake_credential" "production" {
  project_id                        = dbtcloud_project.this.id
  auth_type                         = "keypair"
  user                              = var.snowflake_user
  private_key_wo                    = var.snowflake_private_key
  private_key_wo_version            = var.private_key_version
  private_key_passphrase_wo         = var.private_key_passphrase
  private_key_passphrase_wo_version = var.private_key_passphrase == null ? null : var.passphrase_version
  num_threads                       = var.threads
  schema                            = var.prod_schema
}

resource "dbtcloud_snowflake_credential" "ci" {
  project_id                        = dbtcloud_project.this.id
  auth_type                         = "keypair"
  user                              = var.snowflake_user
  private_key_wo                    = var.snowflake_private_key
  private_key_wo_version            = var.private_key_version
  private_key_passphrase_wo         = var.private_key_passphrase
  private_key_passphrase_wo_version = var.private_key_passphrase == null ? null : var.passphrase_version
  num_threads                       = var.threads
  schema                            = var.ci_schema
}

resource "dbtcloud_environment" "development" {
  dbt_version   = var.dbt_version
  name          = "Development"
  project_id    = dbtcloud_project.this.id
  type          = "development"
  connection_id = var.connection_id
}

resource "dbtcloud_environment" "production" {
  dbt_version     = var.dbt_version
  name            = "Production"
  project_id      = dbtcloud_project.this.id
  type            = "deployment"
  deployment_type = "production"
  connection_id   = var.connection_id
  credential_id   = dbtcloud_snowflake_credential.production.credential_id
}

resource "dbtcloud_environment" "ci" {
  dbt_version     = var.dbt_version
  name            = "CI"
  project_id      = dbtcloud_project.this.id
  type            = "deployment"
  deployment_type = "staging"
  connection_id   = var.connection_id
  credential_id   = dbtcloud_snowflake_credential.ci.credential_id
}

resource "dbtcloud_job" "daily_production_build" {
  count = var.enable_daily_build ? 1 : 0

  dbt_version                = var.dbt_version
  cost_optimization_features = ["dbt_state"]
  environment_id             = dbtcloud_environment.production.environment_id
  execute_steps              = ["dbt build"]
  generate_docs              = true
  is_active                  = true
  name                       = "Daily Production build"
  num_threads                = var.threads
  project_id                 = dbtcloud_project.this.id
  run_generate_sources       = true
  target_name                = "prod"

  triggers = {
    github_webhook       = false
    git_provider_webhook = false
    schedule             = true
    on_merge             = false
  }

  schedule_days  = var.daily_build_schedule_days
  schedule_type  = "days_of_week"
  schedule_hours = var.daily_build_schedule_hours

  dynamic "job_completion_trigger_condition" {
    for_each = var.upstream_production_trigger == null ? [] : [var.upstream_production_trigger]

    content {
      job_id     = job_completion_trigger_condition.value.job_id
      project_id = job_completion_trigger_condition.value.project_id
      statuses   = job_completion_trigger_condition.value.statuses
    }
  }
}

resource "dbtcloud_job" "slim_ci" {
  count = var.enable_slim_ci ? 1 : 0

  dbt_version          = var.dbt_version
  environment_id       = dbtcloud_environment.ci.environment_id
  execute_steps        = ["dbt build --select state:modified+ config.access:public"]
  generate_docs        = true
  is_active            = true
  name                 = "Slim CI"
  num_threads          = var.threads
  project_id           = dbtcloud_project.this.id
  run_generate_sources = true
  target_name          = "ci"

  deferring_environment_id = dbtcloud_environment.production.environment_id

  triggers = {
    github_webhook       = true
    git_provider_webhook = true
    schedule             = false
    on_merge             = false
  }
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    dbtcloud = {
      source  = "dbt-labs/dbtcloud"
      version = ">= 0.3.0"
    }
  }
}

provider "dbtcloud" {
  account_id = var.dbt_cloud_account_id
  token      = var.dbt_cloud_service_token
  host_url   = var.dbt_cloud_access_url
}

locals {
  git_remote_url = "git@github.com:example/weather-mesh-demo.git"

  projects = {
    weather_foundation = {
      subdirectory = "projects/weather_foundation"
      prod_schema  = "WEATHER_FOUNDATION_PROD"
      ci_schema    = "WEATHER_FOUNDATION_CI"
    }
    weather_warnings_resilience = {
      subdirectory = "projects/weather_warnings_resilience"
      prod_schema  = "WEATHER_WARNINGS_RESILIENCE_PROD"
      ci_schema    = "WEATHER_WARNINGS_RESILIENCE_CI"
    }
    weather_transport_aviation = {
      subdirectory = "projects/weather_transport_aviation"
      prod_schema  = "WEATHER_TRANSPORT_AVIATION_PROD"
      ci_schema    = "WEATHER_TRANSPORT_AVIATION_CI"
    }
    weather_climate_data_services = {
      subdirectory = "projects/weather_climate_data_services"
      prod_schema  = "WEATHER_CLIMATE_DATA_SERVICES_PROD"
      ci_schema    = "WEATHER_CLIMATE_DATA_SERVICES_CI"
    }
  }
}

resource "dbtcloud_global_connection" "snowflake" {
  name = "Weather Demo Snowflake"

  snowflake = {
    account   = var.snowflake_account
    database  = var.snowflake_database
    warehouse = var.snowflake_warehouse
    role      = var.snowflake_role
  }
}

module "dbt_cloud_projects" {
  for_each = local.projects

  source = "./modules/dbt_cloud_project"

  project_name           = each.key
  project_subdirectory   = each.value.subdirectory
  connection_id          = dbtcloud_global_connection.snowflake.id
  git_remote_url         = local.git_remote_url
  git_clone_strategy     = var.git_clone_strategy
  github_installation_id = var.github_installation_id
  dbt_version            = var.dbt_version
  threads                = var.dbt_threads
  prod_schema            = each.value.prod_schema
  ci_schema              = each.value.ci_schema
  snowflake_user         = var.snowflake_user
  snowflake_private_key  = file(var.snowflake_private_key_path)
  private_key_version    = var.snowflake_private_key_version
  private_key_passphrase = var.snowflake_private_key_passphrase
  passphrase_version     = var.snowflake_private_key_passphrase_version
  enable_daily_build     = var.enable_daily_build
  enable_slim_ci         = var.enable_slim_ci
}

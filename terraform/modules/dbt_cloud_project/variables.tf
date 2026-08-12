variable "project_name" {
  description = "dbt Cloud project name. Must match the dbt_project.yml `name` for cross-project ref resolution."
  type        = string
}

variable "connection_id" {
  description = "ID of a shared dbtcloud_global_connection to attach to this project's environments."
  type        = string
}

variable "project_subdirectory" {
  description = "Path within the shared monorepo where this project's dbt_project.yml lives, e.g. projects/weather_foundation."
  type        = string
}

variable "git_remote_url" {
  description = "Git remote URL of the shared monorepo, e.g. git@github.com:org/repo.git."
  type        = string
}

variable "git_clone_strategy" {
  description = "Clone strategy: github_app | deploy_key | azure_active_directory_app."
  type        = string
  default     = "github_app"
}

variable "github_installation_id" {
  description = "GitHub App installation ID used to clone the monorepo."
  type        = number
}

variable "dbt_version" {
  description = "dbt version (or release track, e.g. fusion-stable) used by this project's environments and jobs."
  type        = string
  default     = "fusion-stable"
}

variable "threads" {
  description = "dbt execution thread count."
  type        = number
  default     = 4
}

variable "prod_schema" {
  description = "Snowflake schema for this project's Production credential."
  type        = string
}

variable "ci_schema" {
  description = "Snowflake schema for this project's CI credential."
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake user dbt Cloud should use for key-pair authentication."
  type        = string
}

variable "snowflake_private_key" {
  description = "Snowflake private key for dbt Cloud key-pair authentication."
  type        = string
  sensitive   = true
}

variable "private_key_version" {
  description = "Version marker for the Snowflake private key. Increment when rotating the key."
  type        = number
  default     = 1
}

variable "private_key_passphrase" {
  description = "Optional passphrase for the Snowflake private key."
  type        = string
  default     = null
  sensitive   = true
}

variable "passphrase_version" {
  description = "Version marker for the Snowflake private key passphrase. Increment when rotating the passphrase."
  type        = number
  default     = 1
}

variable "enable_daily_build" {
  description = "Whether to create the scheduled Daily Production build job."
  type        = bool
  default     = true
}

variable "upstream_production_trigger" {
  description = "Optional upstream production job completion trigger for the Daily Production build job."
  type = object({
    job_id     = number
    project_id = number
    statuses   = optional(list(string), ["success"])
  })
  default = null
}

variable "daily_build_schedule_days" {
  description = "Days of week (0=Sunday) the Daily Production build runs."
  type        = list(number)
  default     = [0, 1, 2, 3, 4, 5, 6]
}

variable "daily_build_schedule_hours" {
  description = "Hours of day the Daily Production build runs."
  type        = list(number)
  default     = [6]
}

variable "enable_slim_ci" {
  description = "Whether to create the PR-triggered Slim CI job."
  type        = bool
  default     = true
}

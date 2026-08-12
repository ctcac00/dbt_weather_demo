variable "dbt_cloud_account_id" {
  description = "dbt platform account ID."
  type        = number
}

variable "dbt_cloud_access_url" {
  description = "dbt platform access URL including /api, for example https://cloud.getdbt.com/api."
  type        = string
}

variable "dbt_cloud_service_token" {
  description = "dbt platform service token with permission to manage projects, repositories, environments, jobs, and credentials."
  type        = string
  sensitive   = true
}

variable "git_clone_strategy" {
  description = "Git clone strategy for the dbt platform repository integration."
  type        = string
  default     = "github_app"
}

variable "github_installation_id" {
  description = "GitHub App installation ID for the repository integration."
  type        = number
}

variable "dbt_version" {
  description = "dbt release track or version for environments and jobs."
  type        = string
  default     = "fusion-stable"
}

variable "dbt_threads" {
  description = "Thread count for dbt jobs."
  type        = number
  default     = 4
}

variable "enable_daily_build" {
  description = "Whether to create scheduled production jobs."
  type        = bool
  default     = true
}

variable "enable_slim_ci" {
  description = "Whether to create slim CI jobs."
  type        = bool
  default     = true
}

variable "snowflake_account" {
  description = "Existing Snowflake account locator or identifier for the dbt Cloud connection."
  type        = string
}

variable "snowflake_database" {
  description = "Existing Snowflake database for the dbt Cloud connection."
  type        = string
}

variable "snowflake_warehouse" {
  description = "Existing Snowflake warehouse for the dbt Cloud connection."
  type        = string
}

variable "snowflake_role" {
  description = "Existing Snowflake role for the dbt Cloud connection."
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake user dbt Cloud should use for key-pair authentication."
  type        = string
}

variable "snowflake_private_key_path" {
  description = "Path to a Snowflake private key file for dbt Cloud key-pair authentication."
  type        = string
}

variable "snowflake_private_key_version" {
  description = "Version marker for the Snowflake private key. Increment when rotating the key file."
  type        = number
  default     = 1
}

variable "snowflake_private_key_passphrase" {
  description = "Optional passphrase for the Snowflake private key."
  type        = string
  default     = null
  sensitive   = true
}

variable "snowflake_private_key_passphrase_version" {
  description = "Version marker for the Snowflake private key passphrase. Increment when rotating the passphrase."
  type        = number
  default     = 1
}

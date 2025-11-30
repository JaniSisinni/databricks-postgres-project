variable "gcp_project_id" {
  type = string
}

variable "gcp_project_number" {
  type = string
}

variable "gcp_service_account" {
  type = string
}

variable "bronze_bucket" {
  type = string
}

variable "silver_bucket" {
  type = string
}

variable "databricks_host" {
  type = string
}

variable "databricks_pat" {
  type = string
}

variable "cloud_sql_instance" {
  type = string
  default = "products-dev-7789:europe-west3:products-dev-f33"
}

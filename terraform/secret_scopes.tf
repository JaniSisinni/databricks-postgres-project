resource "databricks_secret_scope" "gcp" {
  name                     = "gcp-cloudsql-secrets"
  initial_manage_principal = "users"
}

resource "google_secret_manager_secret_version" "username" {
  secret = "projects/${var.gcp_project_number}/secrets/project-products"
}

data "google_secret_manager_secret_version" "db_username" {
  secret  = "projects/${var.gcp_project_number}/secrets/project-products"
  version = "latest"
}

data "google_secret_manager_secret_version" "db_password" {
  secret  = "projects/${var.gcp_project_number}/secrets/project-products"
  version = "latest"
}

resource "databricks_secret" "username" {
  key          = "db_username"
  scope        = databricks_secret_scope.gcp.name
  string_value = data.google_secret_manager_secret_version.db_username.secret_data
}

resource "databricks_secret" "password" {
  key          = "db_password"
  scope        = databricks_secret_scope.gcp.name
  string_value = data.google_secret_manager_secret_version.db_password.secret_data
}

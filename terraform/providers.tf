terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.30.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "databricks" {
  host  = var.databricks_host
  token = var.databricks_pat
}

provider "google" {
  project = var.gcp_project_id
  impersonate_service_account = var.gcp_service_account
}

provider "google-beta" {
  project = var.gcp_project_id
  impersonate_service_account = var.gcp_service_account
}

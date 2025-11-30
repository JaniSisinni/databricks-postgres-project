resource "google_storage_bucket_iam_member" "bronze_access" {
  bucket = replace(var.bronze_bucket, "gs://", "")
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.gcp_service_account}"
}

resource "google_storage_bucket_iam_member" "silver_access" {
  bucket = replace(var.silver_bucket, "gs://", "")
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.gcp_service_account}"
}

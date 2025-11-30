output "bronze_job_id" {
  value = databricks_job.bronze_ingest_job.id
}

output "dlt_pipeline_id" {
  value = databricks_pipeline.silver_dlt_pipeline.id
}

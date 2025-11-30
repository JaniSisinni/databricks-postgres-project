resource "databricks_job" "bronze_ingest_job" {
  name = "bronze_ingest_job"

  email_notifications {
    on_failure = ["user@company.de"]
    on_success = ["user@company.de"]
  }

  schedule {
    quartz_cron_expression = "0 0 6 * * ?"
    timezone_id            = "Europe/Berlin"
  }

  job_cluster {
    job_cluster_key = "bronze_cluster"
    new_cluster {
      spark_version = "16.4.x-scala2.12"
      node_type_id  = "n1-standard-4"
      num_workers   = 1

      init_scripts {
        dbfs {
          destination = databricks_dbfs_file.cloud_sql_proxy.path
        }
      }
    }
  }

  task {
    task_key = "bronze_ingestion"
    spark_python_task {
      python_file = "notebooks/bronze/bronze_ingest.py"
    }
    job_cluster_key = "bronze_cluster"
  }
}

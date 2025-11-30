resource "databricks_pipeline" "silver_dlt_pipeline" {
  name = "silver_dlt_pipeline"

  storage = "gs://products-dev-silver/_dlt_storage"
  edition = "core"

  library {
    notebook {
      path = "notebooks/silver_dlt/dlt_pipeline.sql"
    }
  }

  cluster {
    label       = "default"
    num_workers = 1
    node_type_id = "n1-standard-4"
    spark_version = "16.4.x-scala2.12"

    init_scripts {
      dbfs {
        destination = databricks_dbfs_file.cloud_sql_proxy.path
      }
    }
  }

  configuration = {
    "pipeline.trigger.interval" = "24h"
  }
}

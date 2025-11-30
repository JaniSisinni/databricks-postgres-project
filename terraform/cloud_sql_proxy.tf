resource "databricks_dbfs_file" "cloud_sql_proxy" {
  source      = "${path.module}/../notebooks/init_scripts/cloud_sql_proxy.sh"
  path        = "dbfs:/databricks/init/cloud_sql_proxy.sh"
  overwrite   = true
}

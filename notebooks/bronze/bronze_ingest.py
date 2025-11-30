from pyspark.sql import SparkSession
from pyspark.sql.functions import col, max as spark_max
from pyspark.sql.utils import AnalysisException
import yaml
import os

from src.common.logger import get_logger
from src.common.helpers import get_last_ingested_value, update_ingestion_checkpoint

logger = get_logger(__name__)

# Load configuration

CONFIG_PATH = "/Workspace/Repos/databricks-postgress-project/config/bronze_config.yml"

with open(CONFIG_PATH, "r") as f:
    config = yaml.safe_load(f)

BRONZE_BUCKET = config["gcs"]["bronze_bucket"]
TABLES = config["source"]["tables"]
DB_NAME = config["source"]["db_name"]
JDBC_HOST = config["source"]["jdbc_host"]
JDBC_PORT = config["source"]["jdbc_port"]
CHECKPOINT_PATH = config["checkpoint_path"]

# Databricks Secrets 
DB_USER = dbutils.secrets.get(scope=config["secrets"]["scope"], key="db_username")
DB_PASS = dbutils.secrets.get(scope=config["secrets"]["scope"], key="db_password")

# Create Spark session
spark = SparkSession.builder.appName("bronze_ingest").getOrCreate()

# JDBC Connection string (IAM)
jdbc_url = f"jdbc:postgresql://{JDBC_HOST}:{JDBC_PORT}/{DB_NAME}"

connection_properties = {
    "user": DB_USER,
    "password": DB_PASS,
    "driver": "org.postgresql.Driver",
    "ssl": "true",
    "sslmode": "prefer"
}

# Ingest
def ingest_table(table_name: str):
    logger.info(f"Starting ingestion for table: {table_name}")

    incremental_col = "id"  
    checkpoint_file = f"{CHECKPOINT_PATH}/{table_name}.json"

    last_value = get_last_ingested_value(spark, checkpoint_file)
    logger.info(f"Latest ingested value for {table_name}: {last_value}")

    query = f"(SELECT * FROM {table_name}"
    if last_value is not None:
        query += f" WHERE {incremental_col} > {last_value}"
    query += ") AS tmp"

    try:
        df = (
            spark.read.format("jdbc")
            .option("url", jdbc_url)
            .option("query", query)
            .options(**connection_properties)
            .load()
        )
    except Exception as e:
        logger.error(f"Error reading from PostgreSQL: {table_name} — {e}")
        raise

    if df.count() == 0:
        logger.info(f"No new rows for {table_name}. Skipping write.")
        return

    # Determine latest surrogate key
    new_max = df.select(spark_max(col(incremental_col))).collect()[0][0]
    logger.info(f"New max ID for table {table_name}: {new_max}")

    # Write to GCS 
    target_path = f"{BRONZE_BUCKET}/{table_name}/"
    (
        df.write.mode("append")
        .option("compression", "snappy")
        .parquet(target_path)
    )

    update_ingestion_checkpoint(spark, checkpoint_file, new_max)

    logger.info(f"Successfully ingested {table_name}, rows={df.count()}")


for table in TABLES:
    ingest_table(table)

logger.info("Bronze ingestion completed successfully.")

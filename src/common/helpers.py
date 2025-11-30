import json
import os
from pyspark.sql import SparkSession

def get_last_ingested_value(spark, path):
    try:
        df = spark.read.json(path)
        return df.collect()[0]["last_value"]
    except:
        return None

def update_ingestion_checkpoint(spark, path, value):
    data = [{"last_value": value}]
    spark.createDataFrame(data).write.mode("overwrite").json(path)

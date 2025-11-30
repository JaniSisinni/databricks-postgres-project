import pytest
from unittest.mock import patch, MagicMock
from pyspark.sql.functions import col
import json
import os

from src.common.helpers import (
    get_last_ingested_value,
    update_ingestion_checkpoint
)

# Incremental ingestion tests
def test_incremental_filtering(spark):
    data = [
        {"id": 1, "sale_num": 10},
        {"id": 2, "sale_num": 11},
        {"id": 5, "sale_num": 12}
    ]

    df = spark.createDataFrame(data)

    last_ingested = 2
    filtered = df.filter(col("id") > last_ingested)

    assert filtered.count() == 1
    assert filtered.collect()[0]["id"] == 5


# Schema inference tests
def test_schema_inference(spark):
    data = [
        {"id": 1, "sale_num": 10, "product_name": "X", "quantity": 4}
    ]
    df = spark.createDataFrame(data)

    expected_columns = ["id", "sale_num", "product_name", "quantity"]

    assert set(df.columns) == set(expected_columns)


# Checkpoint logic tests
def test_update_and_read_checkpoint(spark, tmp_path):
    path = f"{tmp_path}/checkpoint.json"

    update_ingestion_checkpoint(spark, path, 50)
    val = get_last_ingested_value(spark, path)

    assert val == 50


# Write-to-GCS tests (mocked)
def test_write_to_gcs_mocked(spark):
    df = spark.createDataFrame([{"id": 1, "sale_num": 9}])

    with patch("pyspark.sql.DataFrameWriter.parquet") as mock_write:
        df.write.mode("append").parquet("gs://products-dev-bronze/products")

        mock_write.assert_called_once()


# Error-handling tests
def test_error_missing_column(spark):
    data = [{"wrong": 1}]
    df = spark.createDataFrame(data)

    with pytest.raises(Exception):
        df.select("sale_num").collect()

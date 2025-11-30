# databricks-postgres-project
Azure Databricks + GCP (Cloud SQL + GCS + Secret Manager) + DLT + Terraform + GitHub Actions

## 1. Overview

This repository implements a multi-cloud data ingestion and transformation pipeline:

- **Azure Databricks** (compute + jobs + DLT)
- **GCP Cloud SQL PostgreSQL** (source)
- **GCS** (Bronze/Silver storage)
- **GCP Secret Manager** (credentials)
- **Cloud SQL Auth Proxy** (IAM authentication)
- **Terraform** (infrastructure-as-code)
- **GitHub Actions** (CI/CD with OIDC)

The architecture follows a layered paradigm:

- **Bronze:** PySpark ingestion from PostgreSQL → Parquet on GCS  
- **Silver:** Delta Live Tables (SQL) → Joined, curated table

## 2. Architecture Diagram

                         +------------------------+
                         |   GitHub Actions CI/CD |
                         |  terraform.yml         |
                         |  databricks_deploy.yml |
                         +-----------+------------+
                                     |
                                     v
                   +-------------------------------------------------+
                   |                   Terraform                     |
                   |-------------------------------------------------|
                   | - Databricks jobs & clusters                    |
                   | - DLT pipeline                                  |
                   | - Secret scopes                                 |
                   | - Cloud SQL Proxy init script on DBFS           |
                   | - IAM roles (Cloud SQL, GCS, Secrets)           |
                   +-----------------+-------------------------------+
                                     |
                                     v
         +---------------------------+-----------------------------------+
         |                      Azure Databricks                         |
         |---------------------------------------------------------------|
         |  Bronze Job (PySpark)   |  Silver (Delta Live Tables SQL)     |
         |--------------------------+------------------------------------|
         | - JDBC via Cloud SQL Proxy | Reads Bronze Parquet             |
         | - Incremental on id       | Validates + left-joins            |
         | - Writes Parquet to GCS   | Writes curated table to GCS       |
         +---------------------------+-----------------------------------+
                                     |
                                     v
                     +-------------------------------+
                     |             GCS               |
                     |-------------------------------|
                     | bronze/  silver/company_*     |
                     +-------------------------------+

Source System:
    GCP Cloud SQL PostgreSQL

## 3. Bronze Layer (PySpark)

### Features:
- JDBC ingestion via **Cloud SQL Auth Proxy**
- **IAM Authentication** 
- **Incremental ingestion** using surrogate `id`
- Schema inference
- Writes to:

```
gs://products-dev-bronze/<table_name>/
```

To run manually in Databricks:

```
python notebooks/bronze/bronze_ingest.py
```
## 4. Silver Layer (Delta Live Tables SQL)

### Features:
- Reads all Bronze Parquet datasets from GCS
- Validates schema
- Performs `LEFT JOIN` across:
  - products
  - customers
  - purchases
- Computes:
  - `event_timestamp`
  - `purchase_value = customer_id + purchase_number`
  - `'OK'/'NOK'` confirmation
- Writes to:

```
gs://products-dev-silver/company_products_sale/
```

Start the pipeline:

```
Databricks Workspace → Workflows → Delta Live Tables → silver_dlt_pipeline → Start
```

## 5. CI/CD

### a. Terraform Workflow
Automatically:
- Formats & validates Terraform
- Plans on PR
- Applies infra on `main`

### b. Databricks Deployment Workflow
Automatically:
- Deploys notebooks, configs, jobs
- Validates Databricks Bundle
- Restarts DLT pipeline after deployment

## 6. Authentication Model

### Databricks → GCP:
- Uses **service account impersonation**
- No key files
- No secrets stored in GitHub

### GitHub → GCP:
- Uses **OIDC Workload Identity Federation**
- No long-lived service account keys

## 7. Requirements

Dependencies for local dev:

```
pyspark==3.5.0
google-auth
google-cloud-secret-manager
google-cloud-storage
databricks-cli
pyyaml
```

## 8. Deployment Steps

1. Configure repo secrets:
   - `DATABRICKS_HOST`
   - `DATABRICKS_PAT`

2. Push to `main`
3. GitHub Actions runs:
   - `terraform.yml → infra`
   - `databricks_deploy.yml → jobs + DLT`

4. Bronze + Silver pipelines are ready immediately.


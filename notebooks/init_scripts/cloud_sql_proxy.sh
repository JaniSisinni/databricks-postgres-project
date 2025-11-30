#!/bin/bash

set -e

PROXY_VERSION="1.33.0"
PROXY_URL="https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v${PROXY_VERSION}/cloud-sql-proxy.linux.amd64"

INSTANCE="products-dev-7789:europe-west3:products-dev-f33"
PORT=30999

echo "Downloading Cloud SQL Auth Proxy..."
curl -o /tmp/cloud-sql-proxy "${PROXY_URL}"
chmod +x /tmp/cloud-sql-proxy

echo "Starting Cloud SQL Proxy using IAM..."
/tmp/cloud-sql-proxy \
  --port=${PORT} \
  --auto-iam-authn \
  ${INSTANCE} > /tmp/cloud_sql_proxy.log 2>&1 &

echo "Cloud SQL Proxy started."

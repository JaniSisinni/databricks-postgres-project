--DLT
CREATE OR REFRESH LIVE TABLE bronze_products
COMMENT "Bronze products table loaded from Parquet"
AS SELECT
  *
FROM parquet.`gs://products-dev-bronze/products`;

CREATE OR REFRESH LIVE TABLE bronze_customers
COMMENT "Bronze customers table loaded from Parquet"
AS SELECT
  *
FROM parquet.`gs://products-dev-bronze/customers`;

CREATE OR REFRESH LIVE TABLE bronze_purchases
COMMENT "Bronze purchases table loaded from Parquet"
AS SELECT
  *
FROM parquet.`gs://products-dev-bronze/purchases`;

CREATE OR REFRESH LIVE TABLE validated_products
TBLPROPERTIES ("quality" = "gold")
AS
SELECT *
FROM LIVE.bronze_products
WHERE sale_num IS NOT NULL;

CREATE OR REFRESH LIVE TABLE validated_customers
TBLPROPERTIES ("quality" = "gold")
AS
SELECT *
FROM LIVE.bronze_customers
WHERE sale_num IS NOT NULL;

CREATE OR REFRESH LIVE TABLE validated_purchases
TBLPROPERTIES ("quality" = "gold")
AS
SELECT *
FROM LIVE.bronze_purchases
WHERE sale_num IS NOT NULL;

CREATE OR REFRESH LIVE TABLE company_products_sale
COMMENT "Final Silver table combining products, customers, and purchases"
LOCATION "gs://products-dev-silver/company_products_sale"
AS
SELECT
    p.sale_num,
    p.product_name,
    p.quantity,
    c.customer_name,
    c.customer_id,
    c.customer_account,
    pu.purchase_number,
    pu.product_name AS purchase_product_name,

    current_timestamp() AS event_timestamp,
    (c.customer_id + pu.purchase_number) AS purchase_value,
    CASE WHEN p.quantity > 0 THEN 'OK' ELSE 'NOK' END AS confirmation

FROM LIVE.validated_products p
LEFT JOIN LIVE.validated_customers c ON p.sale_num = c.sale_num
LEFT JOIN LIVE.validated_purchases pu ON p.sale_num = pu.sale_num;

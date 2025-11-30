-- Expect no null sale_num
SELECT COUNT(*) AS cnt
FROM gs.`gs://products-dev-silver/company_products_sale`
WHERE sale_num IS NULL;

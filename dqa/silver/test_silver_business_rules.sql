-- Business rule: quantity > 0 => confirmation = 'OK'
SELECT COUNT(*) AS invalid_cnt
FROM gs.`gs://products-dev-silver/company_products_sale`
WHERE quantity > 0 AND confirmation <> 'OK';

-- Data quality test cho staging.stg_products
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'not_null: product_id, product_name, category, unit_price, cost_price' AS test,
       COUNT(*) AS so_loi
FROM staging.stg_products
WHERE product_id IS NULL OR product_name IS NULL OR category IS NULL
   OR unit_price IS NULL OR cost_price IS NULL
UNION ALL
SELECT 'unique: product_id',
       COUNT(*) - COUNT(DISTINCT product_id) FROM staging.stg_products
UNION ALL
SELECT 'accepted_values: category',
       COUNT(*) FROM staging.stg_products
WHERE category NOT IN ('Thực phẩm', 'Thức uống', 'Chăm sóc cá nhân', 'Gia dụng')
UNION ALL
SELECT 'accepted_values: status',
       COUNT(*) FROM staging.stg_products
WHERE status NOT IN ('Active', 'Discontinued')
UNION ALL
SELECT 'range: unit_price > 0',
       COUNT(*) FROM staging.stg_products WHERE unit_price <= 0
UNION ALL
SELECT 'range: weight_gram > 0',
       COUNT(*) FROM staging.stg_products WHERE weight_gram <= 0
UNION ALL
SELECT 'range: cost_price < unit_price',
       COUNT(*) FROM staging.stg_products WHERE cost_price >= unit_price
UNION ALL
SELECT 'reconcile: so dong bang raw.products',
       ABS((SELECT COUNT(*) FROM staging.stg_products)
         - (SELECT COUNT(DISTINCT TRIM(product_id)) FROM raw.products));

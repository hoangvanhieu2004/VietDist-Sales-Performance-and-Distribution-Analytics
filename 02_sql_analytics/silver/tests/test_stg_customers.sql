-- Data quality test cho staging.stg_customers
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'not_null: customer_id, customer_name, channel, region, status, join_date' AS test,
       COUNT(*) AS so_loi
FROM staging.stg_customers
WHERE customer_id IS NULL OR customer_name IS NULL OR channel IS NULL
   OR region IS NULL OR status IS NULL OR join_date IS NULL
UNION ALL
SELECT 'unique: customer_id',
       COUNT(*) - COUNT(DISTINCT customer_id) FROM staging.stg_customers
UNION ALL
SELECT 'accepted_values: region',
       COUNT(*) FROM staging.stg_customers
WHERE region NOT IN ('Miền Bắc', 'Miền Trung', 'Miền Nam')
UNION ALL
SELECT 'accepted_values: channel',
       COUNT(*) FROM staging.stg_customers
WHERE channel NOT IN ('Traditional Trade', 'Modern Trade', 'E-commerce')
UNION ALL
SELECT 'accepted_values: status',
       COUNT(*) FROM staging.stg_customers
WHERE status NOT IN ('Active', 'Inactive')
UNION ALL
SELECT 'range: credit_limit >= 0',
       COUNT(*) FROM staging.stg_customers WHERE credit_limit < 0
UNION ALL
SELECT 'reconcile: so dong bang raw.customers',
       ABS((SELECT COUNT(*) FROM staging.stg_customers)
         - (SELECT COUNT(DISTINCT TRIM(customer_id)) FROM raw.customers));

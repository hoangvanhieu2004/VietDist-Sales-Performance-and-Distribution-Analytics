-- Data quality test cho staging.stg_sales_transactions
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'not_null: order_id, product_id, order_date, customer_id, employee_id' AS test,
       COUNT(*) AS so_loi
FROM staging.stg_sales_transactions
WHERE order_id IS NULL OR product_id IS NULL OR order_date IS NULL
   OR customer_id IS NULL OR employee_id IS NULL
UNION ALL
SELECT 'not_null: quantity, net_amount',
       COUNT(*) FROM staging.stg_sales_transactions
WHERE quantity IS NULL OR net_amount IS NULL
UNION ALL
SELECT 'unique: (order_id, product_id)',
       COUNT(*) - COUNT(DISTINCT (order_id, product_id)) FROM staging.stg_sales_transactions
UNION ALL
SELECT 'accepted_values: delivery_status',
       COUNT(*) FROM staging.stg_sales_transactions
WHERE delivery_status NOT IN ('Delivered', 'Delivering', 'Cancelled')
UNION ALL
SELECT 'accepted_values: region',
       COUNT(*) FROM staging.stg_sales_transactions
WHERE region NOT IN ('Miền Bắc', 'Miền Trung', 'Miền Nam')
UNION ALL
SELECT 'range: quantity > 0',
       COUNT(*) FROM staging.stg_sales_transactions WHERE quantity <= 0
UNION ALL
SELECT 'range: 0 <= net_amount <= gross_amount',
       COUNT(*) FROM staging.stg_sales_transactions
WHERE net_amount < 0 OR net_amount > gross_amount;

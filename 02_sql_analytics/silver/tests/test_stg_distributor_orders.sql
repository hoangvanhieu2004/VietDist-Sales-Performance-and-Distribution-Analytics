-- Data quality test cho staging.stg_distributor_orders
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'not_null: order_id, product_id, order_date, distributor_id, qty_ordered, qty_delivered, expected_delivery_date' AS test,
       COUNT(*) AS so_loi
FROM staging.stg_distributor_orders
WHERE order_id IS NULL OR product_id IS NULL OR order_date IS NULL OR distributor_id IS NULL
   OR qty_ordered IS NULL OR qty_delivered IS NULL OR expected_delivery_date IS NULL
UNION ALL
SELECT 'unique: (order_id, product_id)',
       COUNT(*) - COUNT(DISTINCT (order_id, product_id)) FROM staging.stg_distributor_orders
UNION ALL
SELECT 'accepted_values: delivery_status',
       COUNT(*) FROM staging.stg_distributor_orders
WHERE delivery_status NOT IN ('Delivered', 'Partial', 'Cancelled')
UNION ALL
SELECT 'accepted_values: payment_terms',
       COUNT(*) FROM staging.stg_distributor_orders
WHERE payment_terms NOT IN ('COD', 'NET15', 'NET30', 'NET45')
UNION ALL
SELECT 'accepted_values: channel',
       COUNT(*) FROM staging.stg_distributor_orders
WHERE channel NOT IN ('Traditional Trade', 'Modern Trade', 'E-commerce')
UNION ALL
SELECT 'accepted_values: region',
       COUNT(*) FROM staging.stg_distributor_orders
WHERE region NOT IN ('Miền Bắc', 'Miền Trung', 'Miền Nam')
UNION ALL
SELECT 'range: qty_ordered > 0',
       COUNT(*) FROM staging.stg_distributor_orders WHERE qty_ordered <= 0
UNION ALL
SELECT 'range: 0 <= qty_delivered <= qty_ordered',
       COUNT(*) FROM staging.stg_distributor_orders
WHERE qty_delivered < 0 OR qty_delivered > qty_ordered
UNION ALL
SELECT 'range: actual_delivery_date >= order_date',
       COUNT(*) FROM staging.stg_distributor_orders WHERE actual_delivery_date < order_date
UNION ALL
-- Theo dõi: số dòng cờ tính lại khác cờ gốc phải đúng bằng 177 như lúc profiling
SELECT 'monitor: is_ontime khac is_ontime_source = 177',
       ABS(COUNT(*) FILTER (WHERE is_ontime IS DISTINCT FROM is_ontime_source) - 177)
FROM staging.stg_distributor_orders
UNION ALL
SELECT 'reconcile: so dong bang raw.distributor_orders',
       ABS((SELECT COUNT(*) FROM staging.stg_distributor_orders)
         - (SELECT COUNT(DISTINCT (TRIM(order_id), TRIM(product_id))) FROM raw.distributor_orders));

-- Data quality test cho dwh.fact_sales
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'completeness: so dong bang stg_sales_transactions' AS test,
       ABS((SELECT COUNT(*) FROM dwh.fact_sales) - (SELECT COUNT(*) FROM staging.stg_sales_transactions)) AS so_loi
UNION ALL
-- Phép nối không được làm nhân dòng
SELECT 'unique: (order_id, product_id)',
       COUNT(*) - COUNT(DISTINCT (order_id, product_id)) FROM dwh.fact_sales
UNION ALL
SELECT 'temporal_join: moi dong co employee_sk',
       COUNT(*) FROM dwh.fact_sales WHERE employee_sk IS NULL
UNION ALL
SELECT 'relationships: date_key -> dim_date',
       COUNT(*) FROM dwh.fact_sales f
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_date d WHERE d.date_key = f.date_key)
UNION ALL
SELECT 'relationships: customer_id -> dim_customers',
       COUNT(*) FROM dwh.fact_sales f
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_customers c WHERE c.customer_id = f.customer_id)
UNION ALL
SELECT 'relationships: product_id -> dim_products',
       COUNT(*) FROM dwh.fact_sales f
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_products p WHERE p.product_id = f.product_id)
UNION ALL
SELECT 'reconcile: tong net_amount bang stg_sales_transactions',
       ABS((SELECT SUM(net_amount) FROM dwh.fact_sales)
         - (SELECT SUM(net_amount) FROM staging.stg_sales_transactions))
UNION ALL
SELECT 'reconcile: tong revenue_amount bang net_amount cua don Delivered',
       ABS((SELECT SUM(revenue_amount) FROM dwh.fact_sales)
         - (SELECT SUM(net_amount) FROM staging.stg_sales_transactions WHERE delivery_status = 'Delivered'))
UNION ALL
SELECT 'not_null: cost_amount',
       COUNT(*) FROM dwh.fact_sales WHERE cost_amount IS NULL
UNION ALL
-- Theo dõi: 547 dòng ghi sau ngày nghỉ, khớp lần đếm ở Task 2.3
SELECT 'monitor: is_after_resign = 547',
       ABS(COUNT(*) FILTER (WHERE is_after_resign) - 547) FROM dwh.fact_sales;

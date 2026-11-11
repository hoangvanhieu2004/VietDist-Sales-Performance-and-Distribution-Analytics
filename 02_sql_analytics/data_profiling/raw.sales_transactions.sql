-- Cấu trúc cột
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'sales_transactions'
ORDER BY ordinal_position;

-- Số dòng và % thiếu của cột khóa
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(order_id), '')    IS NULL) / COUNT(*), 2) AS pct_null_order_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(order_date), '')  IS NULL) / COUNT(*), 2) AS pct_null_order_date,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(customer_id), '') IS NULL) / COUNT(*), 2) AS pct_null_customer_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(employee_id), '') IS NULL) / COUNT(*), 2) AS pct_null_employee_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(product_id), '')  IS NULL) / COUNT(*), 2) AS pct_null_product_id
FROM raw.sales_transactions;
 

-- Số dòng trùng theo đơn hàng và sản phẩm:
SELECT 
	COUNT(*) AS duplicate_keys, 
	COALESCE(SUM(so_lan - 1), 0) AS extra_rows
FROM (
    SELECT 
    	order_id, product_id, 
    	COUNT(*) AS so_lan
    FROM raw.sales_transactions
    GROUP BY order_id, product_id
    HAVING COUNT(*) > 1
) t;


-- Đếm giá trị sai định dạng
SELECT
    COUNT(*) FILTER (WHERE order_date !~ '^\d{4}-\d{2}-\d{2}$')   AS bad_order_date,
    COUNT(*) FILTER (WHERE quantity   !~ '^\d+$')                 AS bad_quantity,
    COUNT(*) FILTER (WHERE unit_price !~ '^\d+$')                 AS bad_unit_price,
    COUNT(*) FILTER (WHERE net_amount !~ '^\d+(\.\d+)?$')         AS bad_net_amount
FROM raw.sales_transactions;


-- Liệt kê các giá trị khác nhau của những cột phân loại, để phát hiện cách viết không thống nhất:
SELECT 'region' AS cot, region AS gia_tri, COUNT(*) AS so_dong FROM raw.sales_transactions GROUP BY region
UNION ALL
SELECT 'channel', channel, COUNT(*) FROM raw.sales_transactions GROUP BY channel
UNION ALL
SELECT 'delivery_status', delivery_status, COUNT(*) FROM raw.sales_transactions GROUP BY delivery_status
UNION ALL
SELECT 'payment_status', payment_status, COUNT(*) FROM raw.sales_transactions GROUP BY payment_status
ORDER BY 1, 3 DESC;



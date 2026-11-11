-- Cấu trúc cột
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'customers'
ORDER BY ordinal_position;


-- Số dòng và % thiếu của cột khóa
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(customer_id), '')   IS NULL) / COUNT(*), 2) AS pct_null_customer_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(customer_name), '') IS NULL) / COUNT(*), 2) AS pct_null_customer_name,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(channel), '')       IS NULL) / COUNT(*), 2) AS pct_null_channel,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(region), '')        IS NULL) / COUNT(*), 2) AS pct_null_region,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(phone), '')         IS NULL) / COUNT(*), 2) AS pct_null_phone,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(tax_code), '')      IS NULL) / COUNT(*), 2) AS pct_null_tax_code,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(join_date), '')     IS NULL) / COUNT(*), 2) AS pct_null_join_date
FROM raw.customers;


-- Số dòng trùng theo mã khách hàng
SELECT
    COUNT(*) AS duplicate_keys,
    COALESCE(SUM(so_lan - 1), 0) AS extra_rows
FROM (
    SELECT
        customer_id,
        COUNT(*) AS so_lan
    FROM raw.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) t;


-- Đếm giá trị sai định dạng (bỏ qua ô trống ở phone và tax_code)
SELECT
    COUNT(*) FILTER (WHERE join_date    !~ '^\d{4}-\d{2}-\d{2}$')     AS bad_join_date,
    COUNT(*) FILTER (WHERE credit_limit !~ '^\d+$')                   AS bad_credit_limit,
    COUNT(*) FILTER (WHERE phone <> ''    AND phone    !~ '^\d{10,11}$') AS bad_phone,
    COUNT(*) FILTER (WHERE tax_code <> '' AND tax_code !~ '^\d{10}$')    AS bad_tax_code
FROM raw.customers;


-- Liệt kê các giá trị khác nhau của những cột phân loại, để phát hiện cách viết không thống nhất:
SELECT 'customer_type' AS cot, customer_type AS gia_tri, COUNT(*) AS so_dong FROM raw.customers GROUP BY customer_type
UNION ALL
SELECT 'channel', channel, COUNT(*) FROM raw.customers GROUP BY channel
UNION ALL
SELECT 'region', region, COUNT(*) FROM raw.customers GROUP BY region
UNION ALL
SELECT 'status', status, COUNT(*) FROM raw.customers GROUP BY status
ORDER BY 1, 3 DESC;

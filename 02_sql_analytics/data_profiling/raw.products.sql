-- Cấu trúc cột
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'products'
ORDER BY ordinal_position;


-- Số dòng và % thiếu của cột khóa
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(product_id), '')   IS NULL) / COUNT(*), 2) AS pct_null_product_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(product_name), '') IS NULL) / COUNT(*), 2) AS pct_null_product_name,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(category), '')     IS NULL) / COUNT(*), 2) AS pct_null_category,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(unit_price), '')   IS NULL) / COUNT(*), 2) AS pct_null_unit_price,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(cost_price), '')   IS NULL) / COUNT(*), 2) AS pct_null_cost_price,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(launch_date), '')  IS NULL) / COUNT(*), 2) AS pct_null_launch_date
FROM raw.products;


-- Số dòng trùng theo mã sản phẩm
SELECT
    COUNT(*) AS duplicate_keys,
    COALESCE(SUM(so_lan - 1), 0) AS extra_rows
FROM (
    SELECT
        product_id,
        COUNT(*) AS so_lan
    FROM raw.products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) t;


-- Đếm giá trị sai định dạng
SELECT
    COUNT(*) FILTER (WHERE unit_price  !~ '^\d+$')               AS bad_unit_price,
    COUNT(*) FILTER (WHERE cost_price  !~ '^\d+$')               AS bad_cost_price,
    COUNT(*) FILTER (WHERE weight_gram !~ '^\d+$')               AS bad_weight_gram,
    COUNT(*) FILTER (WHERE launch_date !~ '^\d{4}-\d{2}-\d{2}$') AS bad_launch_date
FROM raw.products;


-- Liệt kê các giá trị khác nhau của những cột phân loại, để phát hiện cách viết không thống nhất:
SELECT 'category' AS cot, category AS gia_tri, COUNT(*) AS so_dong FROM raw.products GROUP BY category
UNION ALL
SELECT 'sub_category', sub_category, COUNT(*) FROM raw.products GROUP BY sub_category
UNION ALL
SELECT 'unit', unit, COUNT(*) FROM raw.products GROUP BY unit
UNION ALL
SELECT 'status', status, COUNT(*) FROM raw.products GROUP BY status
ORDER BY 1, 3 DESC;


-- Kiểm tra hợp lý: sản phẩm có giá vốn lớn hơn hoặc bằng giá bán (bán lỗ hoặc hòa vốn)
SELECT
    COUNT(*) FILTER (WHERE cost_price::NUMERIC >  unit_price::NUMERIC) AS cost_above_price,
    COUNT(*) FILTER (WHERE cost_price::NUMERIC =  unit_price::NUMERIC) AS cost_equal_price,
    COUNT(*) FILTER (WHERE unit_price::NUMERIC <= 0)                   AS zero_or_negative_price
FROM raw.products
WHERE unit_price ~ '^\d+$'
  AND cost_price ~ '^\d+$';

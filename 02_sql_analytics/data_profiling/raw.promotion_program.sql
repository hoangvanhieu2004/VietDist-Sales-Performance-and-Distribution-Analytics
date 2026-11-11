-- Cấu trúc cột
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'promotion_program'
ORDER BY ordinal_position;


-- Số dòng và % thiếu của cột khóa
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(promotion_id), '')        IS NULL) / COUNT(*), 2) AS pct_null_promotion_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(promotion_name), '')      IS NULL) / COUNT(*), 2) AS pct_null_promotion_name,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(promotion_type), '')      IS NULL) / COUNT(*), 2) AS pct_null_promotion_type,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(start_date), '')          IS NULL) / COUNT(*), 2) AS pct_null_start_date,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(end_date), '')            IS NULL) / COUNT(*), 2) AS pct_null_end_date,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(applicable_products), '') IS NULL) / COUNT(*), 2) AS pct_null_applicable_products,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(discount_pct), '')        IS NULL) / COUNT(*), 2) AS pct_null_discount_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(budget_vnd), '')          IS NULL) / COUNT(*), 2) AS pct_null_budget_vnd,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(status), '')              IS NULL) / COUNT(*), 2) AS pct_null_status
FROM raw.promotion_program;


-- Số dòng trùng theo mã chương trình
SELECT
    COUNT(*) AS duplicate_keys,
    COALESCE(SUM(so_lan - 1), 0) AS extra_rows
FROM (
    SELECT
        promotion_id,
        COUNT(*) AS so_lan
    FROM raw.promotion_program
    GROUP BY promotion_id
    HAVING COUNT(*) > 1
) t;


-- Đếm giá trị sai định dạng
SELECT
    COUNT(*) FILTER (WHERE start_date          !~ '^\d{4}-\d{2}-\d{2}$')   AS bad_start_date,
    COUNT(*) FILTER (WHERE end_date            !~ '^\d{4}-\d{2}-\d{2}$')   AS bad_end_date,
    COUNT(*) FILTER (WHERE discount_pct        !~ '^\d+(\.\d+)?$')         AS bad_discount_pct,
    COUNT(*) FILTER (WHERE min_order_quantity  !~ '^\d+$')                 AS bad_min_order_quantity,
    COUNT(*) FILTER (WHERE budget_vnd          !~ '^\d+(\.\d+)?$')         AS bad_budget_vnd,
    COUNT(*) FILTER (WHERE actual_cost_vnd     !~ '^\d+(\.\d+)?$')         AS bad_actual_cost_vnd,
    COUNT(*) FILTER (WHERE applicable_products !~ '^PRD\d+(\|PRD\d+)*$')   AS bad_applicable_products
FROM raw.promotion_program;


-- Liệt kê các giá trị khác nhau của những cột phân loại, để phát hiện cách viết không thống nhất:
SELECT 'promotion_type' AS cot, promotion_type AS gia_tri, COUNT(*) AS so_dong FROM raw.promotion_program GROUP BY promotion_type
UNION ALL
SELECT 'target_channel', target_channel, COUNT(*) FROM raw.promotion_program GROUP BY target_channel
UNION ALL
SELECT 'target_region', target_region, COUNT(*) FROM raw.promotion_program GROUP BY target_region
UNION ALL
SELECT 'status', status, COUNT(*) FROM raw.promotion_program GROUP BY status
ORDER BY 1, 3 DESC;


-- Kiểm tra hợp lý: ngày, mức giảm giá và chi phí so với ngân sách
SELECT
    COUNT(*) FILTER (WHERE end_date::DATE < start_date::DATE)                    AS ket_thuc_truoc_bat_dau,
    COUNT(*) FILTER (WHERE discount_pct::NUMERIC > 100)                          AS giam_tren_100,
    COUNT(*) FILTER (WHERE actual_cost_vnd::NUMERIC > budget_vnd::NUMERIC)       AS vuot_ngan_sach,
    ROUND(SUM(actual_cost_vnd::NUMERIC) / NULLIF(SUM(budget_vnd::NUMERIC), 0) * 100, 2) AS ty_le_chi_tren_ngan_sach_pct,
    MIN(start_date) AS bat_dau_som_nhat,
    MAX(end_date)   AS ket_thuc_muon_nhat
FROM raw.promotion_program
WHERE start_date      ~ '^\d{4}-\d{2}-\d{2}$'
  AND end_date        ~ '^\d{4}-\d{2}-\d{2}$'
  AND discount_pct    ~ '^\d+(\.\d+)?$'
  AND budget_vnd      ~ '^\d+(\.\d+)?$'
  AND actual_cost_vnd ~ '^\d+(\.\d+)?$';


-- Đối chiếu với products: tách applicable_products thành từng mã sản phẩm
-- string_to_array cắt chuỗi theo dấu |, unnest biến mảng thành nhiều dòng
SELECT
    COUNT(*)                                    AS so_cap_ctkm_san_pham,
    COUNT(DISTINCT x.product_id)                AS so_san_pham_khac_nhau,
    COUNT(*) FILTER (WHERE p.product_id IS NULL) AS ma_san_pham_khong_ton_tai
FROM raw.promotion_program pp
CROSS JOIN LATERAL unnest(string_to_array(pp.applicable_products, '|')) AS x(product_id)
LEFT JOIN raw.products p ON p.product_id = x.product_id;

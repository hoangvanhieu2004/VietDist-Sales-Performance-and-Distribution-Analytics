-- Cấu trúc cột
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'return_transactions'
ORDER BY ordinal_position;


-- Số dòng và % thiếu của cột khóa
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(return_id), '')         IS NULL) / COUNT(*), 2) AS pct_null_return_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(original_order_id), '') IS NULL) / COUNT(*), 2) AS pct_null_original_order_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(return_date), '')       IS NULL) / COUNT(*), 2) AS pct_null_return_date,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(customer_id), '')       IS NULL) / COUNT(*), 2) AS pct_null_customer_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(product_id), '')        IS NULL) / COUNT(*), 2) AS pct_null_product_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(return_quantity), '')   IS NULL) / COUNT(*), 2) AS pct_null_return_quantity,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(return_amount), '')     IS NULL) / COUNT(*), 2) AS pct_null_return_amount,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(return_reason), '')     IS NULL) / COUNT(*), 2) AS pct_null_return_reason
FROM raw.return_transactions;


-- Số dòng trùng theo mã phiếu trả
SELECT
    COUNT(*) AS duplicate_keys,
    COALESCE(SUM(so_lan - 1), 0) AS extra_rows
FROM (
    SELECT
        return_id,
        COUNT(*) AS so_lan
    FROM raw.return_transactions
    GROUP BY return_id
    HAVING COUNT(*) > 1
) t;


-- Đếm giá trị sai định dạng
SELECT
    COUNT(*) FILTER (WHERE return_date     !~ '^\d{4}-\d{2}-\d{2}$') AS bad_return_date,
    COUNT(*) FILTER (WHERE return_month    !~ '^\d{1,2}$')           AS bad_return_month,
    COUNT(*) FILTER (WHERE return_quantity !~ '^\d+$')               AS bad_return_quantity,
    COUNT(*) FILTER (WHERE unit_price      !~ '^\d+(\.\d+)?$')       AS bad_unit_price,
    COUNT(*) FILTER (WHERE return_amount   !~ '^\d+(\.\d+)?$')       AS bad_return_amount
FROM raw.return_transactions;


-- Liệt kê các giá trị khác nhau của những cột phân loại, để phát hiện cách viết không thống nhất:
SELECT 'region' AS cot, region AS gia_tri, COUNT(*) AS so_dong FROM raw.return_transactions GROUP BY region
UNION ALL
SELECT 'return_reason', return_reason, COUNT(*) FROM raw.return_transactions GROUP BY return_reason
UNION ALL
SELECT 'status', status, COUNT(*) FROM raw.return_transactions GROUP BY status
ORDER BY 1, 3 DESC;


-- Kiểm tra hợp lý trong bảng: thành tiền và tháng có khớp không
SELECT
    COUNT(*) FILTER (WHERE return_quantity::NUMERIC = 0)                                         AS tra_0_san_pham,
    COUNT(*) FILTER (WHERE ABS(return_amount::NUMERIC
                               - return_quantity::NUMERIC * unit_price::NUMERIC) > 1)            AS return_amount_lech,
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM return_date::DATE) <> return_month::INTEGER)     AS return_month_lech
FROM raw.return_transactions
WHERE return_date     ~ '^\d{4}-\d{2}-\d{2}$'
  AND return_month    ~ '^\d{1,2}$'
  AND return_quantity ~ '^\d+$'
  AND unit_price      ~ '^\d+(\.\d+)?$'
  AND return_amount   ~ '^\d+(\.\d+)?$';


-- Đối chiếu với đơn gốc trong sales_transactions (ghép theo mã đơn và mã sản phẩm)
SELECT
    COUNT(*)                                                                    AS so_phieu,
    COUNT(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM raw.sales_transactions x
                                       WHERE x.order_id = r.original_order_id))   AS khong_co_ma_don,
    COUNT(*) FILTER (WHERE s.order_id IS NULL)                                   AS khong_co_dong_san_pham,
    COUNT(*) FILTER (WHERE r.return_quantity::NUMERIC > s.quantity::NUMERIC)    AS tra_nhieu_hon_mua,
    COUNT(*) FILTER (WHERE r.return_date::DATE < s.order_date::DATE)            AS tra_truoc_ngay_mua,
    COUNT(*) FILTER (WHERE r.customer_id <> s.customer_id)                      AS khac_khach_hang,
    COUNT(*) FILTER (WHERE r.unit_price::NUMERIC <> s.unit_price::NUMERIC)      AS khac_don_gia,
    COUNT(*) FILTER (WHERE s.delivery_status = 'Cancelled')                     AS tra_tu_don_da_huy
FROM raw.return_transactions r
LEFT JOIN raw.sales_transactions s
    ON  s.order_id   = r.original_order_id
    AND s.product_id = r.product_id
WHERE r.return_date     ~ '^\d{4}-\d{2}-\d{2}$'
  AND r.return_quantity ~ '^\d+$'
  AND r.unit_price      ~ '^\d+(\.\d+)?$';

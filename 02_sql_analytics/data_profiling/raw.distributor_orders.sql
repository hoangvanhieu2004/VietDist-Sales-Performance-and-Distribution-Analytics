-- Cấu trúc cột
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'distributor_orders'
ORDER BY ordinal_position;


-- Số dòng và % thiếu của cột khóa
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(order_id), '')             IS NULL) / COUNT(*), 2) AS pct_null_order_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(order_date), '')           IS NULL) / COUNT(*), 2) AS pct_null_order_date,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(distributor_id), '')       IS NULL) / COUNT(*), 2) AS pct_null_distributor_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(product_id), '')           IS NULL) / COUNT(*), 2) AS pct_null_product_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(qty_ordered), '')          IS NULL) / COUNT(*), 2) AS pct_null_qty_ordered,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(qty_delivered), '')        IS NULL) / COUNT(*), 2) AS pct_null_qty_delivered,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(actual_delivery_date), '') IS NULL) / COUNT(*), 2) AS pct_null_actual_delivery_date
FROM raw.distributor_orders;


-- Số dòng trùng theo đơn hàng và sản phẩm
SELECT
    COUNT(*) AS duplicate_keys,
    COALESCE(SUM(so_lan - 1), 0) AS extra_rows
FROM (
    SELECT
        order_id, product_id,
        COUNT(*) AS so_lan
    FROM raw.distributor_orders
    GROUP BY order_id, product_id
    HAVING COUNT(*) > 1
) t;


-- Đếm giá trị sai định dạng (bỏ qua ô trống ở actual_delivery_date)
SELECT
    COUNT(*) FILTER (WHERE order_date             !~ '^\d{4}-\d{2}-\d{2}$') AS bad_order_date,
    COUNT(*) FILTER (WHERE expected_delivery_date !~ '^\d{4}-\d{2}-\d{2}$') AS bad_expected_date,
    COUNT(*) FILTER (WHERE actual_delivery_date <> '' AND actual_delivery_date !~ '^\d{4}-\d{2}-\d{2}$') AS bad_actual_date,
    COUNT(*) FILTER (WHERE qty_ordered       !~ '^\d+$')            AS bad_qty_ordered,
    COUNT(*) FILTER (WHERE qty_delivered     !~ '^\d+$')            AS bad_qty_delivered,
    COUNT(*) FILTER (WHERE fill_rate_pct     !~ '^\d+(\.\d+)?$')    AS bad_fill_rate_pct,
    COUNT(*) FILTER (WHERE distributor_price !~ '^\d+(\.\d+)?$')    AS bad_distributor_price,
    COUNT(*) FILTER (WHERE gross_amount      !~ '^\d+(\.\d+)?$')    AS bad_gross_amount,
    COUNT(*) FILTER (WHERE delivered_amount  !~ '^\d+(\.\d+)?$')    AS bad_delivered_amount
FROM raw.distributor_orders;


-- Liệt kê các giá trị khác nhau của những cột phân loại, để phát hiện cách viết không thống nhất:
SELECT 'region' AS cot, region AS gia_tri, COUNT(*) AS so_dong FROM raw.distributor_orders GROUP BY region
UNION ALL
SELECT 'channel', channel, COUNT(*) FROM raw.distributor_orders GROUP BY channel
UNION ALL
SELECT 'product_category', product_category, COUNT(*) FROM raw.distributor_orders GROUP BY product_category
UNION ALL
SELECT 'delivery_status', delivery_status, COUNT(*) FROM raw.distributor_orders GROUP BY delivery_status
UNION ALL
SELECT 'ontime_delivery', ontime_delivery, COUNT(*) FROM raw.distributor_orders GROUP BY ontime_delivery
UNION ALL
SELECT 'payment_terms', payment_terms, COUNT(*) FROM raw.distributor_orders GROUP BY payment_terms
ORDER BY 1, 3 DESC;


-- Kiểm tra hợp lý: số lượng, ngày giao, tỷ lệ giao và thành tiền có khớp nhau không
SELECT
    COUNT(*) FILTER (WHERE qty_delivered::NUMERIC > qty_ordered::NUMERIC)                 AS giao_nhieu_hon_dat,
    COUNT(*) FILTER (WHERE qty_ordered::NUMERIC = 0)                                       AS dat_bang_0,
    COUNT(*) FILTER (WHERE actual_delivery_date <> ''
                       AND actual_delivery_date::DATE < order_date::DATE)                  AS giao_truoc_ngay_dat,
    COUNT(*) FILTER (WHERE qty_ordered::NUMERIC > 0
                       AND ABS(fill_rate_pct::NUMERIC
                               - 100.0 * qty_delivered::NUMERIC / qty_ordered::NUMERIC) > 0.01) AS fill_rate_lech,
    COUNT(*) FILTER (WHERE ABS(gross_amount::NUMERIC
                               - qty_ordered::NUMERIC * distributor_price::NUMERIC) > 1)   AS gross_amount_lech,
    COUNT(*) FILTER (WHERE ABS(delivered_amount::NUMERIC
                               - qty_delivered::NUMERIC * distributor_price::NUMERIC) > 1) AS delivered_amount_lech,
    COUNT(*) FILTER (WHERE actual_delivery_date <> ''
                       AND (actual_delivery_date::DATE <= expected_delivery_date::DATE)
                           <> (ontime_delivery = 'Yes'))                                   AS ontime_lech
FROM raw.distributor_orders
WHERE order_date             ~ '^\d{4}-\d{2}-\d{2}$'
  AND expected_delivery_date ~ '^\d{4}-\d{2}-\d{2}$'
  AND (actual_delivery_date = '' OR actual_delivery_date ~ '^\d{4}-\d{2}-\d{2}$')
  AND qty_ordered       ~ '^\d+$'
  AND qty_delivered     ~ '^\d+$'
  AND fill_rate_pct     ~ '^\d+(\.\d+)?$'
  AND distributor_price ~ '^\d+(\.\d+)?$'
  AND gross_amount      ~ '^\d+(\.\d+)?$'
  AND delivered_amount  ~ '^\d+(\.\d+)?$';


-- Chẩn đoán: các dòng có ontime_delivery không khớp với ngày giao so với ngày hẹn
SELECT
    delivery_status,
    ontime_delivery,
    actual_delivery_date::DATE - expected_delivery_date::DATE AS so_ngay_tre,
    COUNT(*) AS so_dong
FROM raw.distributor_orders
WHERE (actual_delivery_date::DATE <= expected_delivery_date::DATE) <> (ontime_delivery = 'Yes')
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;


-- Chẩn đoán: số lượng giao và thành tiền theo trạng thái giao hàng
SELECT
    delivery_status,
    COUNT(*) AS so_dong,
    COUNT(*) FILTER (WHERE qty_delivered::NUMERIC = 0)    AS giao_0,
    COUNT(*) FILTER (WHERE delivered_amount::NUMERIC = 0) AS thanh_tien_0,
    MIN(qty_delivered::NUMERIC / NULLIF(qty_ordered::NUMERIC, 0)) AS ty_le_giao_min,
    MAX(qty_delivered::NUMERIC / NULLIF(qty_ordered::NUMERIC, 0)) AS ty_le_giao_max
FROM raw.distributor_orders
GROUP BY 1
ORDER BY 1;

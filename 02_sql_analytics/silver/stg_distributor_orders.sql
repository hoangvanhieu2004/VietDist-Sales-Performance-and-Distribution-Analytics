-- Xóa bảng cũ để chạy lại được nhiều lần.
-- CASCADE xóa luôn các view Gold phụ thuộc, nên luôn chạy lại Gold sau Silver
DROP TABLE IF EXISTS staging.stg_distributor_orders CASCADE;

CREATE TABLE staging.stg_distributor_orders AS
WITH ranked AS (
    -- Đánh số các dòng trùng khóa, dòng nạp mới nhất được số 1
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY TRIM(order_id), TRIM(product_id)
               ORDER BY _ingested_at DESC
           ) AS rn
    FROM raw.distributor_orders
)
SELECT
    TRIM(order_id)                               AS order_id,
    TRIM(product_id)                             AS product_id,
    order_date::DATE                             AS order_date,
    TRIM(distributor_id)                         AS distributor_id,
    TRIM(region)                                 AS region,
    TRIM(channel)                                AS channel,
    TRIM(product_category)                       AS product_category,
    qty_ordered::INTEGER                         AS qty_ordered,
    qty_delivered::INTEGER                       AS qty_delivered,
    fill_rate_pct::NUMERIC(6, 2)                 AS fill_rate_pct,
    unit_price_list::NUMERIC(18, 2)              AS unit_price_list,
    distributor_price::NUMERIC(18, 2)            AS distributor_price,
    gross_amount::NUMERIC(18, 2)                 AS gross_amount,
    delivered_amount::NUMERIC(18, 2)             AS delivered_amount,
    expected_delivery_date::DATE                 AS expected_delivery_date,
    NULLIF(TRIM(actual_delivery_date), '')::DATE AS actual_delivery_date,
    (TRIM(ontime_delivery) = 'Yes')              AS is_ontime_source,   -- cờ gốc, giữ để đối chiếu
    (NULLIF(TRIM(actual_delivery_date), '')::DATE
        <= expected_delivery_date::DATE)         AS is_ontime,          -- cờ tính lại (giả định A-15)
    TRIM(delivery_status)                        AS delivery_status,
    TRIM(payment_terms)                          AS payment_terms,
    _source_file,
    _batch_id,
    _ingested_at
FROM ranked
WHERE rn = 1                                                      -- chỉ giữ 1 dòng mỗi khóa
  AND NULLIF(NULLIF(TRIM(order_id), ''), 'nan')   IS NOT NULL      -- bỏ dòng thiếu khóa
  AND NULLIF(NULLIF(TRIM(product_id), ''), 'nan') IS NOT NULL;

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_distributor_orders ADD PRIMARY KEY (order_id, product_id);

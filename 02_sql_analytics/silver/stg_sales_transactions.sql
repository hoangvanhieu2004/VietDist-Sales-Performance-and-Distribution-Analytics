-- Xóa bảng cũ để chạy lại được nhiều lần.
-- CASCADE xóa luôn các view Gold phụ thuộc, nên luôn chạy lại Gold sau Silver
DROP TABLE IF EXISTS staging.stg_sales_transactions CASCADE;

CREATE TABLE staging.stg_sales_transactions AS
WITH ranked AS (
    -- Đánh số các dòng trùng khóa, dòng nạp mới nhất được số 1
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY TRIM(order_id), TRIM(product_id)
               ORDER BY _ingested_at DESC
           ) AS rn
    FROM raw.sales_transactions
)
SELECT
    TRIM(order_id)                   AS order_id,
    TRIM(product_id)                 AS product_id,
    order_date::DATE                 AS order_date,
    order_month::INTEGER             AS order_month,
    order_quarter::INTEGER           AS order_quarter,
    order_year::INTEGER              AS order_year,
    TRIM(customer_id)                AS customer_id,
    TRIM(employee_id)                AS employee_id,
    TRIM(region)                     AS region,
    TRIM(province)                   AS province,
    TRIM(channel)                    AS channel,
    TRIM(product_category)           AS product_category,
    quantity::INTEGER                AS quantity,
    unit_price::NUMERIC(18, 2)       AS unit_price,
    discount_pct::NUMERIC(5, 2)      AS discount_pct,
    discount_amount::NUMERIC(18, 2)  AS discount_amount,
    gross_amount::NUMERIC(18, 2)     AS gross_amount,
    net_amount::NUMERIC(18, 2)       AS net_amount,
    TRIM(delivery_status)            AS delivery_status,
    TRIM(payment_method)             AS payment_method,
    TRIM(payment_status)             AS payment_status,
    _source_file,
    _batch_id,
    _ingested_at
FROM ranked
WHERE rn = 1                                                         -- chỉ giữ 1 dòng mỗi khóa
  AND NULLIF(NULLIF(TRIM(order_id), ''), 'nan')   IS NOT NULL         -- bỏ dòng thiếu khóa
  AND NULLIF(NULLIF(TRIM(product_id), ''), 'nan') IS NOT NULL;

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_sales_transactions
    ADD PRIMARY KEY (order_id, product_id);

-- Xóa bảng cũ để chạy lại được nhiều lần.
-- CASCADE xóa luôn các view Gold phụ thuộc, nên luôn chạy lại Gold sau Silver
DROP TABLE IF EXISTS staging.stg_return_transactions CASCADE;

CREATE TABLE staging.stg_return_transactions AS
WITH ranked AS (
    -- Đánh số các dòng trùng khóa, dòng nạp mới nhất được số 1
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY TRIM(return_id) ORDER BY _ingested_at DESC) AS rn
    FROM raw.return_transactions
)
SELECT
    TRIM(return_id)                    AS return_id,
    TRIM(original_order_id)            AS original_order_id,
    TRIM(product_id)                   AS product_id,
    return_date::DATE                  AS return_date,
    return_month::INTEGER              AS return_month,
    TRIM(customer_id)                  AS customer_id,
    TRIM(employee_id)                  AS employee_id,
    TRIM(region)                       AS region,
    TRIM(province)                     AS province,
    return_quantity::INTEGER           AS return_quantity,
    unit_price::NUMERIC(18, 2)         AS unit_price,
    return_amount::NUMERIC(18, 2)      AS return_amount,
    TRIM(return_reason)                AS return_reason,
    TRIM(status)                       AS status,
    _source_file,
    _batch_id,
    _ingested_at
FROM ranked
WHERE rn = 1                                                   -- chỉ giữ 1 dòng mỗi khóa
  AND NULLIF(NULLIF(TRIM(return_id), ''), 'nan') IS NOT NULL;   -- bỏ dòng thiếu khóa

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_return_transactions ADD PRIMARY KEY (return_id);

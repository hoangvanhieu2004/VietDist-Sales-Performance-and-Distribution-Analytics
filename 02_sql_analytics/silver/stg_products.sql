-- Xóa bảng cũ để chạy lại được nhiều lần.
-- CASCADE xóa luôn các view Gold phụ thuộc, nên luôn chạy lại Gold sau Silver
DROP TABLE IF EXISTS staging.stg_products CASCADE;

CREATE TABLE staging.stg_products AS
WITH ranked AS (
    -- Đánh số các dòng trùng khóa, dòng nạp mới nhất được số 1
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY TRIM(product_id) ORDER BY _ingested_at DESC) AS rn
    FROM raw.products
)
SELECT
    TRIM(product_id)              AS product_id,
    TRIM(product_name)            AS product_name,
    TRIM(category)                AS category,
    TRIM(sub_category)            AS sub_category,
    TRIM(unit)                    AS unit,
    unit_price::NUMERIC(18, 2)    AS unit_price,
    cost_price::NUMERIC(18, 2)    AS cost_price,
    weight_gram::INTEGER          AS weight_gram,
    TRIM(status)                  AS status,
    launch_date::DATE             AS launch_date,
    _source_file,
    _batch_id,
    _ingested_at
FROM ranked
WHERE rn = 1                                                    -- chỉ giữ 1 dòng mỗi khóa
  AND NULLIF(NULLIF(TRIM(product_id), ''), 'nan') IS NOT NULL;   -- bỏ dòng thiếu khóa

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_products ADD PRIMARY KEY (product_id);

-- Xóa bảng cũ để chạy lại được nhiều lần.
-- CASCADE xóa luôn các view Gold phụ thuộc, nên luôn chạy lại Gold sau Silver
DROP TABLE IF EXISTS staging.stg_customers CASCADE;

CREATE TABLE staging.stg_customers AS
WITH ranked AS (
    -- Đánh số các dòng trùng khóa, dòng nạp mới nhất được số 1
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY TRIM(customer_id) ORDER BY _ingested_at DESC) AS rn
    FROM raw.customers
)
SELECT
    TRIM(customer_id)                 AS customer_id,
    TRIM(customer_name)               AS customer_name,
    TRIM(customer_type)               AS customer_type,
    TRIM(channel)                     AS channel,
    TRIM(province)                    AS province,
    TRIM(region)                      AS region,
    TRIM(address)                     AS address,
    NULLIF(TRIM(phone), '')           AS phone,          -- giữ dạng chữ để không mất số 0 ở đầu
    NULLIF(TRIM(tax_code), '')        AS tax_code,       -- ô trống thành NULL (51,75% số dòng)
    join_date::DATE                   AS join_date,
    credit_limit::NUMERIC(18, 2)      AS credit_limit,
    TRIM(status)                      AS status,
    _source_file,
    _batch_id,
    _ingested_at
FROM ranked
WHERE rn = 1                                                     -- chỉ giữ 1 dòng mỗi khóa
  AND NULLIF(NULLIF(TRIM(customer_id), ''), 'nan') IS NOT NULL;   -- bỏ dòng thiếu khóa

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_customers ADD PRIMARY KEY (customer_id);

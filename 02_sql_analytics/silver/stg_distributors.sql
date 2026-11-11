-- Xóa bảng cũ để chạy lại được nhiều lần.
-- CASCADE xóa luôn các view Gold phụ thuộc, nên luôn chạy lại Gold sau Silver
DROP TABLE IF EXISTS staging.stg_distributors CASCADE;

CREATE TABLE staging.stg_distributors AS
WITH ranked AS (
    -- Đánh số các dòng trùng khóa, dòng nạp mới nhất được số 1
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY TRIM(distributor_id) ORDER BY _ingested_at DESC) AS rn
    FROM raw.distributors
)
SELECT
    TRIM(distributor_id)                     AS distributor_id,
    TRIM(distributor_name)                   AS distributor_name,
    TRIM(tier)                               AS tier,
    TRIM(channel)                            AS channel,
    TRIM(province)                           AS province,
    TRIM(region)                             AS region,
    TRIM(contact_person)                     AS contact_person,
    NULLIF(TRIM(phone), '')                  AS phone,
    NULLIF(TRIM(email), '')                  AS email,
    NULLIF(TRIM(tax_code), '')               AS tax_code,
    join_date::DATE                          AS join_date,
    credit_limit::NUMERIC(18, 2)             AS credit_limit,
    TRIM(status)                             AS status,
    NULLIF(TRIM(assigned_supervisor_id), '') AS assigned_supervisor_id,
    _source_file,
    _batch_id,
    _ingested_at
FROM ranked
WHERE rn = 1                                                        -- chỉ giữ 1 dòng mỗi khóa
  AND NULLIF(NULLIF(TRIM(distributor_id), ''), 'nan') IS NOT NULL;   -- bỏ dòng thiếu khóa

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_distributors ADD PRIMARY KEY (distributor_id);

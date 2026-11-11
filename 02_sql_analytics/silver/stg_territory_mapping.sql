-- Xóa bảng cũ để chạy lại được nhiều lần.
-- CASCADE xóa luôn các view Gold phụ thuộc, nên luôn chạy lại Gold sau Silver
DROP TABLE IF EXISTS staging.stg_territory_mapping CASCADE;

CREATE TABLE staging.stg_territory_mapping AS
WITH ranked AS (
    -- Đánh số các dòng trùng khóa, dòng nạp mới nhất được số 1
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY TRIM(territory_id) ORDER BY _ingested_at DESC) AS rn
    FROM raw.territory_mapping
)
SELECT
    TRIM(territory_id)       AS territory_id,
    TRIM(employee_id)        AS employee_id,
    TRIM(customer_id)        AS customer_id,
    TRIM(region)             AS region,
    TRIM(team)               AS team,
    effective_date::DATE     AS effective_date,
    expiry_date::DATE        AS expiry_date,      -- giữ 9999-12-31 làm quy ước "chưa hết hạn"
    TRIM(version)            AS version,
    _source_file,
    _batch_id,
    _ingested_at
FROM ranked
WHERE rn = 1                                                      -- chỉ giữ 1 dòng mỗi khóa
  AND NULLIF(NULLIF(TRIM(territory_id), ''), 'nan') IS NOT NULL;   -- bỏ dòng thiếu khóa

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_territory_mapping ADD PRIMARY KEY (territory_id);

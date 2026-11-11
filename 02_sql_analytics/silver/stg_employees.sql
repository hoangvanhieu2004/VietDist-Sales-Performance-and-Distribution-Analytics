-- Xóa bảng cũ để chạy lại được nhiều lần.
-- CASCADE xóa luôn các view Gold phụ thuộc, nên luôn chạy lại Gold sau Silver
DROP TABLE IF EXISTS staging.stg_employees CASCADE;

CREATE TABLE staging.stg_employees AS
WITH ranked AS (
    -- Đánh số các dòng trùng khóa (nhân viên, phiên bản), dòng nạp mới nhất được số 1
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY TRIM(employee_id), TRIM(version)
               ORDER BY _ingested_at DESC
           ) AS rn
    FROM raw.employees
)
SELECT
    TRIM(employee_id)                     AS employee_id,
    TRIM(version)                         AS version,
    effective_date::DATE                  AS effective_date,
    TRIM(full_name)                       AS full_name,
    TRIM(gender)                          AS gender,
    date_of_birth::DATE                   AS date_of_birth,
    join_date::DATE                       AS join_date,
    TRIM(position)                        AS position,
    TRIM(region)                          AS region,
    TRIM(team)                            AS team,
    NULLIF(TRIM(email), '')               AS email,
    NULLIF(TRIM(phone), '')               AS phone,
    TRIM(status)                          AS status,
    NULLIF(TRIM(resign_date), '')::DATE   AS resign_date,     -- ô trống thành NULL rồi mới đổi sang ngày
    NULLIF(TRIM(transfer_note), '')       AS transfer_note,
    _source_file,
    _batch_id,
    _ingested_at
FROM ranked
WHERE rn = 1                                                     -- chỉ giữ 1 dòng mỗi khóa
  AND NULLIF(NULLIF(TRIM(employee_id), ''), 'nan') IS NOT NULL    -- bỏ dòng thiếu khóa
  AND NULLIF(NULLIF(TRIM(version), ''), 'nan')     IS NOT NULL;

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_employees ADD PRIMARY KEY (employee_id, version);

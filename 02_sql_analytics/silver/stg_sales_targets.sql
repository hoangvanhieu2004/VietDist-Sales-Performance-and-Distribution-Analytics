-- Xóa bảng cũ để chạy lại được nhiều lần.
-- CASCADE xóa luôn các view Gold phụ thuộc, nên luôn chạy lại Gold sau Silver
DROP TABLE IF EXISTS staging.stg_sales_targets CASCADE;

CREATE TABLE staging.stg_sales_targets AS
WITH ranked AS (
    -- Đánh số các dòng trùng khóa (nhân viên, năm, tháng, phiên bản), dòng nạp mới nhất được số 1
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY TRIM(employee_id), TRIM(year), TRIM(month), TRIM(plan_version)
               ORDER BY _ingested_at DESC
           ) AS rn
    FROM raw.sales_targets_raw
)
SELECT
    TRIM(employee_id)                       AS employee_id,
    year::INTEGER                           AS year,
    month::INTEGER                          AS month,
    TRIM(plan_version)                      AS plan_version,
    version_date::DATE                      AS version_date,
    effective_from::DATE                    AS effective_from,
    effective_to::DATE                      AS effective_to_source,   -- giá trị nguồn, không dùng (giả định A-06)
    TRIM(employee_name)                     AS employee_name,
    TRIM(region)                            AS region,
    TRIM(team)                              AS team,
    target_revenue::NUMERIC(18, 2)          AS target_revenue,
    target_quantity::INTEGER                AS target_quantity,
    target_new_customers::INTEGER           AS target_new_customers,
    _source_file,
    _batch_id,
    _ingested_at
FROM ranked
WHERE rn = 1                                                        -- chỉ giữ 1 dòng mỗi khóa
  AND NULLIF(NULLIF(TRIM(employee_id), ''), 'nan')  IS NOT NULL      -- bỏ dòng thiếu khóa
  AND NULLIF(NULLIF(TRIM(plan_version), ''), 'nan') IS NOT NULL;

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_sales_targets
    ADD PRIMARY KEY (employee_id, year, month, plan_version);

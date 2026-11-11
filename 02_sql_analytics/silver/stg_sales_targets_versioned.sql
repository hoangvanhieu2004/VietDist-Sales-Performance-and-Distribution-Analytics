-- Xóa bảng cũ để chạy lại được nhiều lần.
-- CASCADE xóa luôn các view Gold phụ thuộc, nên luôn chạy lại Gold sau Silver
DROP TABLE IF EXISTS staging.stg_sales_targets_versioned CASCADE;

CREATE TABLE staging.stg_sales_targets_versioned AS
WITH version_periods AS (
    -- Mỗi phiên bản một dòng. Ngày hết hạn = ngày trước khi phiên bản kế tiếp bắt đầu,
    -- phiên bản cuối cùng hết hạn ngày cuối năm (giả định A-06)
    SELECT
        year,
        plan_version,
        MIN(version_date)   AS version_date,
        MIN(effective_from) AS effective_from,
        COALESCE(
            LEAD(MIN(effective_from)) OVER (PARTITION BY year ORDER BY MIN(effective_from)) - 1,
            make_date(year, 12, 31)
        ) AS effective_to
    FROM staging.stg_sales_targets
    GROUP BY year, plan_version
),
month_version AS (
    -- Với mỗi tháng: phiên bản có khoảng hiệu lực chứa ngày đầu tháng (giả định A-08)
    SELECT m.year, m.month, v.plan_version
    FROM (SELECT DISTINCT year, month FROM staging.stg_sales_targets) m
    JOIN version_periods v
        ON  v.year = m.year
        AND make_date(m.year, m.month, 1) BETWEEN v.effective_from AND v.effective_to
)
SELECT
    t.employee_id,
    t.year,
    t.month,
    t.plan_version,
    SUBSTRING(t.plan_version FROM 2)::INTEGER AS version_number,   -- 'v2' -> 2, để sắp xếp
    vp.version_date,
    vp.effective_from,
    vp.effective_to,
    (mv.plan_version IS NOT NULL)             AS is_latest,        -- TRUE = phiên bản đang hiệu lực của tháng
    t.employee_name,
    t.region,
    t.team,
    t.target_revenue,
    t.target_quantity,
    t.target_new_customers,
    t._source_file,
    t._batch_id,
    t._ingested_at
FROM staging.stg_sales_targets t
JOIN version_periods vp
    ON vp.year = t.year AND vp.plan_version = t.plan_version
LEFT JOIN month_version mv
    ON mv.year = t.year AND mv.month = t.month AND mv.plan_version = t.plan_version;

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_sales_targets_versioned
    ADD PRIMARY KEY (employee_id, year, month, plan_version);

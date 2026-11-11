-- View fact_targets: chỉ tiêu theo nhân viên, tháng và phiên bản (temporal fact)
-- Giữ mọi phiên bản để so sánh thực tế với từng phiên bản kế hoạch
DROP VIEW IF EXISTS dwh.fact_targets;

CREATE VIEW dwh.fact_targets AS
WITH resign AS (
    -- Ngày nghỉ việc của mỗi nhân viên (nếu có)
    SELECT employee_id, MAX(resign_date) AS resign_date
    FROM staging.stg_employees
    GROUP BY employee_id
)
SELECT
    t.employee_id,
    e.employee_sk,                                                   -- nối theo ngày đầu tháng
    t.year,
    t.month,
    TO_CHAR(make_date(t.year, t.month, 1), 'YYYYMMDD')::INTEGER AS date_key,
    t.plan_version,
    t.version_number,
    t.version_date,
    t.effective_from,
    t.effective_to,
    t.is_latest,                                                     -- phiên bản hiệu lực của tháng (A-08)
    (r.resign_date IS NULL
     OR r.resign_date > make_date(t.year, t.month, 1)) AS is_active_month,  -- còn làm ngày đầu tháng (A-24)
    t.target_revenue,
    t.target_quantity,
    t.target_new_customers
FROM staging.stg_sales_targets_versioned t
LEFT JOIN dwh.dim_employees e
    ON  e.employee_id = t.employee_id
    AND make_date(t.year, t.month, 1) BETWEEN e.effective_from AND e.effective_to
LEFT JOIN resign r ON r.employee_id = t.employee_id;

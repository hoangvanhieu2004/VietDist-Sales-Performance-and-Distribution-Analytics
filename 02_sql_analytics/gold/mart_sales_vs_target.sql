-- View mart_sales_vs_target: thực tế so với chỉ tiêu theo nhân viên, tháng và phiên bản kế hoạch
-- Lưu ý khi dùng: thực tế lặp lại ở mỗi phiên bản của cùng tháng.
-- Luôn lọc một phiên bản (is_latest = TRUE, hoặc một plan_version cụ thể) trước khi cộng.
DROP VIEW IF EXISTS dwh.mart_sales_vs_target;

CREATE VIEW dwh.mart_sales_vs_target AS
WITH sales AS (
    -- Doanh thu thực tế và số khách đã mua của mỗi nhân viên mỗi tháng (A-01)
    SELECT employee_id,
           EXTRACT(YEAR  FROM order_date)::INTEGER AS year,
           EXTRACT(MONTH FROM order_date)::INTEGER AS month,
           SUM(revenue_amount)                                    AS actual_revenue,
           COUNT(DISTINCT customer_id) FILTER (WHERE is_delivered) AS active_customers
    FROM dwh.fact_sales
    GROUP BY 1, 2, 3
),
returns AS (
    -- Hàng trả được trừ, tính theo tháng trả (A-02)
    SELECT employee_id,
           EXTRACT(YEAR  FROM return_date)::INTEGER AS year,
           EXTRACT(MONTH FROM return_date)::INTEGER AS month,
           SUM(deducted_amount) AS returns_amount
    FROM dwh.fact_returns
    GROUP BY 1, 2, 3
),
actuals AS (
    -- Ghép doanh thu và hàng trả (có tháng chỉ có một trong hai)
    SELECT COALESCE(s.employee_id, r.employee_id) AS employee_id,
           COALESCE(s.year,  r.year)              AS year,
           COALESCE(s.month, r.month)             AS month,
           COALESCE(s.actual_revenue, 0)          AS actual_revenue,
           COALESCE(r.returns_amount, 0)          AS returns_amount,
           COALESCE(s.active_customers, 0)        AS active_customers
    FROM sales s
    FULL JOIN returns r
        ON r.employee_id = s.employee_id AND r.year = s.year AND r.month = s.month
),
target_rows AS (
    -- Mọi dòng chỉ tiêu, mọi phiên bản
    SELECT employee_id, year, month, plan_version, is_latest, target_revenue
    FROM dwh.fact_targets
    UNION ALL
    -- Tháng có thực tế nhưng nhân viên không có chỉ tiêu hiện hành
    SELECT a.employee_id, a.year, a.month, NULL, TRUE, NULL
    FROM actuals a
    WHERE NOT EXISTS (
        SELECT 1 FROM dwh.fact_targets t
        WHERE t.employee_id = a.employee_id AND t.year = a.year
          AND t.month = a.month AND t.is_latest
    )
),
resign AS (
    -- Ngày nghỉ việc của mỗi nhân viên (nếu có)
    SELECT employee_id, MAX(resign_date) AS resign_date
    FROM staging.stg_employees
    GROUP BY employee_id
)
SELECT
    e.employee_sk,
    t.employee_id,
    e.full_name,
    e.region,                                            -- vùng, nhóm tại thời điểm của tháng (SCD2)
    e.team,
    t.year,
    t.month,
    TO_CHAR(make_date(t.year, t.month, 1), 'YYYYMMDD')::INTEGER AS date_key,
    t.plan_version,
    t.is_latest,
    (r.resign_date IS NULL
     OR r.resign_date > make_date(t.year, t.month, 1))  AS is_active_month,    -- A-24
    t.target_revenue,
    COALESCE(a.actual_revenue, 0)                       AS actual_revenue,
    COALESCE(a.returns_amount, 0)                       AS returns_amount,
    COALESCE(a.actual_revenue, 0)
      - COALESCE(a.returns_amount, 0)                   AS net_revenue,        -- doanh thu thuần
    COALESCE(a.active_customers, 0)                     AS active_customers,
    CASE
        WHEN t.target_revenue > 0
         AND (r.resign_date IS NULL OR r.resign_date > make_date(t.year, t.month, 1))
        THEN ROUND((COALESCE(a.actual_revenue, 0) - COALESCE(a.returns_amount, 0))
                   / t.target_revenue * 100, 2)
    END                                                 AS achieve_pct         -- A-12: không chia khi không có chỉ tiêu
FROM target_rows t
LEFT JOIN actuals a
    ON a.employee_id = t.employee_id AND a.year = t.year AND a.month = t.month
LEFT JOIN dwh.dim_employees e
    ON  e.employee_id = t.employee_id
    AND make_date(t.year, t.month, 1) BETWEEN e.effective_from AND e.effective_to
LEFT JOIN resign r ON r.employee_id = t.employee_id;

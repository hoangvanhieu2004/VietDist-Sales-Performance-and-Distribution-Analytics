-- Data quality test cho staging.stg_sales_targets
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'not_null: employee_id, year, month, plan_version, effective_from, target_revenue' AS test,
       COUNT(*) AS so_loi
FROM staging.stg_sales_targets
WHERE employee_id IS NULL OR year IS NULL OR month IS NULL OR plan_version IS NULL
   OR effective_from IS NULL OR target_revenue IS NULL
UNION ALL
SELECT 'unique: (employee_id, year, month, plan_version)',
       COUNT(*) - COUNT(DISTINCT (employee_id, year, month, plan_version)) FROM staging.stg_sales_targets
UNION ALL
SELECT 'accepted_values: month tu 1 den 12',
       COUNT(*) FROM staging.stg_sales_targets WHERE month NOT BETWEEN 1 AND 12
UNION ALL
SELECT 'accepted_values: plan_version (v + so)',
       COUNT(*) FROM staging.stg_sales_targets WHERE plan_version !~ '^v\d+$'
UNION ALL
SELECT 'range: target_revenue > 0, target_quantity > 0, target_new_customers >= 0',
       COUNT(*) FROM staging.stg_sales_targets
WHERE target_revenue <= 0 OR target_quantity <= 0 OR target_new_customers < 0
UNION ALL
-- Chỉ tiêu phiên bản nào thì nhân viên phải có hồ sơ cùng phiên bản đó
SELECT 'relationships: (employee_id, plan_version) -> stg_employees (employee_id, version)',
       COUNT(*) FROM staging.stg_sales_targets t
WHERE NOT EXISTS (
    SELECT 1 FROM staging.stg_employees e
    WHERE e.employee_id = t.employee_id AND e.version = t.plan_version
)
UNION ALL
SELECT 'reconcile: so dong bang raw.sales_targets_raw',
       ABS((SELECT COUNT(*) FROM staging.stg_sales_targets)
         - (SELECT COUNT(DISTINCT (TRIM(employee_id), TRIM(year), TRIM(month), TRIM(plan_version)))
            FROM raw.sales_targets_raw));

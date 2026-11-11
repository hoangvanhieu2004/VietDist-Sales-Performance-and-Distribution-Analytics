-- Data quality test cho staging.stg_employees
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'not_null: employee_id, version, effective_date, full_name, position, region, team, status' AS test,
       COUNT(*) AS so_loi
FROM staging.stg_employees
WHERE employee_id IS NULL OR version IS NULL OR effective_date IS NULL OR full_name IS NULL
   OR position IS NULL OR region IS NULL OR team IS NULL OR status IS NULL
UNION ALL
SELECT 'unique: (employee_id, version)',
       COUNT(*) - COUNT(DISTINCT (employee_id, version)) FROM staging.stg_employees
UNION ALL
SELECT 'accepted_values: region',
       COUNT(*) FROM staging.stg_employees
WHERE region NOT IN ('Miền Bắc', 'Miền Trung', 'Miền Nam')
UNION ALL
SELECT 'accepted_values: status',
       COUNT(*) FROM staging.stg_employees
WHERE status NOT IN ('Active', 'Resigned')
UNION ALL
SELECT 'accepted_values: version (v + so)',
       COUNT(*) FROM staging.stg_employees
WHERE version !~ '^v\d+$'
UNION ALL
SELECT 'consistency: Resigned co resign_date, Active khong co',
       COUNT(*) FROM staging.stg_employees
WHERE (status = 'Resigned' AND resign_date IS NULL)
   OR (status = 'Active'   AND resign_date IS NOT NULL)
UNION ALL
SELECT 'reconcile: so dong bang raw.employees',
       ABS((SELECT COUNT(*) FROM staging.stg_employees)
         - (SELECT COUNT(DISTINCT (TRIM(employee_id), TRIM(version))) FROM raw.employees));

-- Data quality test cho staging.stg_territory_mapping
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'not_null: territory_id, employee_id, customer_id, effective_date, expiry_date, version' AS test,
       COUNT(*) AS so_loi
FROM staging.stg_territory_mapping
WHERE territory_id IS NULL OR employee_id IS NULL OR customer_id IS NULL
   OR effective_date IS NULL OR expiry_date IS NULL OR version IS NULL
UNION ALL
SELECT 'unique: territory_id',
       COUNT(*) - COUNT(DISTINCT territory_id) FROM staging.stg_territory_mapping
UNION ALL
SELECT 'accepted_values: region',
       COUNT(*) FROM staging.stg_territory_mapping
WHERE region NOT IN ('Miền Bắc', 'Miền Trung', 'Miền Nam')
UNION ALL
SELECT 'accepted_values: version (v + so)',
       COUNT(*) FROM staging.stg_territory_mapping
WHERE version !~ '^v\d+$'
UNION ALL
SELECT 'range: expiry_date >= effective_date',
       COUNT(*) FROM staging.stg_territory_mapping WHERE expiry_date < effective_date
UNION ALL
-- Một khách không được có 2 dòng phân vùng với khoảng hiệu lực chồng nhau
SELECT 'no_overlap: customer_id theo thoi gian',
       COUNT(*) FROM staging.stg_territory_mapping a
JOIN staging.stg_territory_mapping b
    ON  a.customer_id  = b.customer_id
    AND a.territory_id < b.territory_id
    AND a.effective_date <= b.expiry_date
    AND b.effective_date <= a.expiry_date
UNION ALL
SELECT 'relationships: customer_id -> stg_customers',
       COUNT(*) FROM staging.stg_territory_mapping t
WHERE NOT EXISTS (SELECT 1 FROM staging.stg_customers c WHERE c.customer_id = t.customer_id)
UNION ALL
SELECT 'relationships: employee_id -> stg_employees',
       COUNT(*) FROM staging.stg_territory_mapping t
WHERE NOT EXISTS (SELECT 1 FROM staging.stg_employees e WHERE e.employee_id = t.employee_id)
UNION ALL
SELECT 'reconcile: so dong bang raw.territory_mapping',
       ABS((SELECT COUNT(*) FROM staging.stg_territory_mapping)
         - (SELECT COUNT(DISTINCT TRIM(territory_id)) FROM raw.territory_mapping));

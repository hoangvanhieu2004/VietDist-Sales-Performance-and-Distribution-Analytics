-- Data quality test cho staging.stg_distributors
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'not_null: distributor_id, distributor_name, tier, channel, region, status, join_date' AS test,
       COUNT(*) AS so_loi
FROM staging.stg_distributors
WHERE distributor_id IS NULL OR distributor_name IS NULL OR tier IS NULL OR channel IS NULL
   OR region IS NULL OR status IS NULL OR join_date IS NULL
UNION ALL
SELECT 'unique: distributor_id',
       COUNT(*) - COUNT(DISTINCT distributor_id) FROM staging.stg_distributors
UNION ALL
SELECT 'accepted_values: tier',
       COUNT(*) FROM staging.stg_distributors
WHERE tier NOT IN ('Nhà phân phối cấp 1', 'Đại lý cấp 2', 'Điểm bán lẻ')
UNION ALL
SELECT 'accepted_values: channel',
       COUNT(*) FROM staging.stg_distributors
WHERE channel NOT IN ('Traditional Trade', 'Modern Trade', 'E-commerce')
UNION ALL
SELECT 'accepted_values: region',
       COUNT(*) FROM staging.stg_distributors
WHERE region NOT IN ('Miền Bắc', 'Miền Trung', 'Miền Nam')
UNION ALL
SELECT 'accepted_values: status',
       COUNT(*) FROM staging.stg_distributors
WHERE status NOT IN ('Active', 'Inactive')
UNION ALL
SELECT 'range: credit_limit >= 0',
       COUNT(*) FROM staging.stg_distributors WHERE credit_limit < 0
UNION ALL
SELECT 'reconcile: so dong bang raw.distributors',
       ABS((SELECT COUNT(*) FROM staging.stg_distributors)
         - (SELECT COUNT(DISTINCT TRIM(distributor_id)) FROM raw.distributors));

-- Data quality test cho dwh.fact_targets và dwh.fact_returns
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'fact_targets completeness: so dong bang stg_sales_targets_versioned' AS test,
       ABS((SELECT COUNT(*) FROM dwh.fact_targets) - (SELECT COUNT(*) FROM staging.stg_sales_targets_versioned)) AS so_loi
UNION ALL
SELECT 'fact_targets unique: (employee_id, year, month, plan_version)',
       COUNT(*) - COUNT(DISTINCT (employee_id, year, month, plan_version)) FROM dwh.fact_targets
UNION ALL
SELECT 'fact_targets temporal_join: moi dong co employee_sk',
       COUNT(*) FROM dwh.fact_targets WHERE employee_sk IS NULL
UNION ALL
SELECT 'fact_targets relationships: date_key -> dim_date',
       COUNT(*) FROM dwh.fact_targets f
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_date d WHERE d.date_key = f.date_key)
UNION ALL
SELECT 'fact_targets monitor: is_latest = 1284',
       ABS(COUNT(*) FILTER (WHERE is_latest) - 1284) FROM dwh.fact_targets
UNION ALL
-- 3 người nghỉ trước 01/06 vẫn có chỉ tiêu hiện hành tháng 6 nhưng không còn làm ngày đầu tháng
SELECT 'fact_targets monitor: is_latest nhung khong active = 3',
       ABS(COUNT(*) FILTER (WHERE is_latest AND NOT is_active_month) - 3) FROM dwh.fact_targets
UNION ALL
SELECT 'fact_returns completeness: so dong bang stg_return_transactions',
       ABS((SELECT COUNT(*) FROM dwh.fact_returns) - (SELECT COUNT(*) FROM staging.stg_return_transactions))
UNION ALL
SELECT 'fact_returns unique: return_id',
       COUNT(*) - COUNT(DISTINCT return_id) FROM dwh.fact_returns
UNION ALL
SELECT 'fact_returns temporal_join: moi dong co employee_sk',
       COUNT(*) FROM dwh.fact_returns WHERE employee_sk IS NULL
UNION ALL
SELECT 'fact_returns relationships: date_key -> dim_date',
       COUNT(*) FROM dwh.fact_returns f
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_date d WHERE d.date_key = f.date_key)
UNION ALL
SELECT 'fact_returns reconcile: tong return_amount bang stg_return_transactions',
       ABS((SELECT SUM(return_amount) FROM dwh.fact_returns)
         - (SELECT SUM(return_amount) FROM staging.stg_return_transactions))
UNION ALL
SELECT 'fact_returns consistency: deducted_amount chi khac 0 voi phieu Da xu ly',
       COUNT(*) FROM dwh.fact_returns
WHERE (status = 'Đã xử lý' AND deducted_amount <> return_amount)
   OR (status <> 'Đã xử lý' AND deducted_amount <> 0);

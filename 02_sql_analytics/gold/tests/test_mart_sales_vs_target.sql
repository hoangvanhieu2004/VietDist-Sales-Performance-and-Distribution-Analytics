-- Data quality test cho dwh.mart_sales_vs_target
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'unique: (employee_id, year, month, plan_version)' AS test,
       COUNT(*) - COUNT(DISTINCT (employee_id, year, month, COALESCE(plan_version, '-'))) AS so_loi
FROM dwh.mart_sales_vs_target
UNION ALL
-- Không (nhân viên, tháng) nào có từ 2 dòng is_latest, để lọc is_latest thì không tính trùng
SELECT 'at_most_one_latest: toi da 1 dong is_latest moi nhan vien moi thang',
       COUNT(*) FROM (
    SELECT employee_id, year, month
    FROM dwh.mart_sales_vs_target
    GROUP BY employee_id, year, month
    HAVING COUNT(*) FILTER (WHERE is_latest) > 1
) x
UNION ALL
-- Mọi (nhân viên, tháng) có thực tế (doanh số hoặc hàng trả) phải có đúng 1 dòng is_latest, để không mất doanh thu.
-- Người đã nghỉ, không có chỉ tiêu hiện hành và không có thực tế, thì được phép không có dòng is_latest
SELECT 'latest_when_actual: co thuc te thi co dung 1 dong is_latest',
       COUNT(*) FROM (
    SELECT employee_id, year, month
    FROM dwh.mart_sales_vs_target
    GROUP BY employee_id, year, month
    HAVING MAX(ABS(actual_revenue) + ABS(returns_amount)) > 0
       AND COUNT(*) FILTER (WHERE is_latest) <> 1
) x
UNION ALL
-- Không mất doanh thu: tổng net_revenue của dòng is_latest = doanh thu fact_sales trừ hàng trả fact_returns
SELECT 'reconcile: net_revenue (is_latest) = fact_sales - fact_returns',
       ABS((SELECT SUM(net_revenue) FROM dwh.mart_sales_vs_target WHERE is_latest)
         - ((SELECT SUM(revenue_amount) FROM dwh.fact_sales)
          - (SELECT SUM(deducted_amount) FROM dwh.fact_returns)))
UNION ALL
SELECT 'no_divide_by_zero: achieve_pct trong khi khong co chi tieu hoac khong con lam',
       COUNT(*) FROM dwh.mart_sales_vs_target
WHERE achieve_pct IS NOT NULL
  AND (target_revenue IS NULL OR target_revenue = 0 OR NOT is_active_month)
UNION ALL
SELECT 'completeness: so dong co chi tieu bang fact_targets',
       ABS((SELECT COUNT(*) FROM dwh.mart_sales_vs_target WHERE plan_version IS NOT NULL)
         - (SELECT COUNT(*) FROM dwh.fact_targets))
UNION ALL
SELECT 'temporal_join: moi dong co employee_sk',
       COUNT(*) FROM dwh.mart_sales_vs_target WHERE employee_sk IS NULL;


-- Tóm tắt theo tháng, chỉ tiêu hiện hành (để đọc, không phải test)
SELECT
    year,
    month,
    STRING_AGG(DISTINCT plan_version, ', ')                        AS phien_ban,
    COUNT(*) FILTER (WHERE plan_version IS NULL)                   AS dong_khong_chi_tieu,
    ROUND(SUM(target_revenue) FILTER (WHERE is_active_month) / 1e9, 2) AS chi_tieu_ty,
    ROUND(SUM(net_revenue) / 1e9, 2)                               AS doanh_thu_thuan_ty,
    ROUND(SUM(net_revenue) FILTER (WHERE achieve_pct IS NOT NULL)
          / NULLIF(SUM(target_revenue) FILTER (WHERE achieve_pct IS NOT NULL), 0) * 100, 1) AS hoan_thanh_pct
FROM dwh.mart_sales_vs_target
WHERE is_latest
GROUP BY year, month
ORDER BY year, month;

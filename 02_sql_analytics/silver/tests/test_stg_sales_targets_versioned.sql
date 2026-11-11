-- Data quality test cho staging.stg_sales_targets_versioned
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'unique: (employee_id, year, month, plan_version)' AS test,
       COUNT(*) - COUNT(DISTINCT (employee_id, year, month, plan_version)) AS so_loi
FROM staging.stg_sales_targets_versioned
UNION ALL
-- Không mất phiên bản cũ: số dòng phải bằng bảng nguồn
SELECT 'reconcile: so dong bang stg_sales_targets',
       ABS((SELECT COUNT(*) FROM staging.stg_sales_targets_versioned)
         - (SELECT COUNT(*) FROM staging.stg_sales_targets))
UNION ALL
-- Mỗi tháng có đúng 1 phiên bản đang hiệu lực
SELECT 'one_version_per_month: dung 1 plan_version is_latest moi thang',
       COUNT(*) FROM (
    SELECT t.year, t.month
    FROM (SELECT DISTINCT year, month FROM staging.stg_sales_targets_versioned) t
    LEFT JOIN staging.stg_sales_targets_versioned v
        ON v.year = t.year AND v.month = t.month AND v.is_latest
    GROUP BY t.year, t.month
    HAVING COUNT(DISTINCT v.plan_version) <> 1
) x
UNION ALL
-- Mỗi nhân viên có tối đa 1 chỉ tiêu hiện hành trong một tháng
SELECT 'one_latest_per_employee_month: toi da 1 dong is_latest',
       COUNT(*) FROM (
    SELECT employee_id, year, month
    FROM staging.stg_sales_targets_versioned
    WHERE is_latest
    GROUP BY employee_id, year, month
    HAVING COUNT(*) > 1
) x
UNION ALL
-- Các phiên bản trong cùng năm có khoảng hiệu lực nối tiếp, không chồng nhau
SELECT 'no_overlap: khoang hieu luc cac phien ban',
       COUNT(*) FROM (SELECT DISTINCT year, plan_version, effective_from, effective_to
                      FROM staging.stg_sales_targets_versioned) a
JOIN (SELECT DISTINCT year, plan_version, effective_from, effective_to
      FROM staging.stg_sales_targets_versioned) b
    ON  a.year = b.year
    AND a.plan_version < b.plan_version
    AND a.effective_from <= b.effective_to
    AND b.effective_from <= a.effective_to
UNION ALL
SELECT 'range: effective_to >= effective_from',
       COUNT(*) FROM staging.stg_sales_targets_versioned WHERE effective_to < effective_from
UNION ALL
-- Theo dõi: 111 nhân viên x 6 tháng (v1) + 103 nhân viên x 6 tháng (v2) = 1.284
SELECT 'monitor: so dong is_latest = 1284',
       ABS(COUNT(*) FILTER (WHERE is_latest) - 1284) FROM staging.stg_sales_targets_versioned
UNION ALL
-- Theo dõi: phiên bản kế hoạch ban hành sau khi hồ sơ nhân viên ghi nhận nghỉ việc
-- không được có chỉ tiêu hiện hành cho người đó (v2 từ 2024-07-01 không có 8 người nghỉ việc).
-- Chỉ tiêu tháng trước đó vẫn thuộc phiên bản cũ. Có tính % hoàn thành hay không là việc của Gold.
SELECT 'monitor: phien ban sau ngay ghi nhan nghi viec khong co chi tieu cho nguoi da nghi',
       COUNT(*) FROM staging.stg_sales_targets_versioned t
JOIN staging.stg_employees e
    ON e.employee_id = t.employee_id AND e.status = 'Resigned'
WHERE t.is_latest
  AND t.effective_from >= e.effective_date;


-- Subtask 2.3.3: kiểm tra logic theo tháng (để đọc, không phải test)
SELECT
    year,
    month,
    STRING_AGG(DISTINCT plan_version, ', ') FILTER (WHERE is_latest)  AS phien_ban_hieu_luc,
    COUNT(*) FILTER (WHERE is_latest)                                  AS so_nv_co_chi_tieu,
    SUM(target_revenue) FILTER (WHERE is_latest)                       AS tong_chi_tieu_hien_hanh,
    SUM(target_revenue) FILTER (WHERE plan_version = 'v1')             AS tong_chi_tieu_v1
FROM staging.stg_sales_targets_versioned
GROUP BY year, month
ORDER BY year, month;

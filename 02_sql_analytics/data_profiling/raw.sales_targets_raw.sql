-- Cấu trúc cột
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'sales_targets_raw'
ORDER BY ordinal_position;


-- Số dòng và % thiếu của cột khóa
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(plan_version), '')         IS NULL) / COUNT(*), 2) AS pct_null_plan_version,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(employee_id), '')          IS NULL) / COUNT(*), 2) AS pct_null_employee_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(year), '')                 IS NULL) / COUNT(*), 2) AS pct_null_year,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(month), '')                IS NULL) / COUNT(*), 2) AS pct_null_month,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(target_revenue), '')       IS NULL) / COUNT(*), 2) AS pct_null_target_revenue,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(target_quantity), '')      IS NULL) / COUNT(*), 2) AS pct_null_target_quantity,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(target_new_customers), '') IS NULL) / COUNT(*), 2) AS pct_null_target_new_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(effective_from), '')       IS NULL) / COUNT(*), 2) AS pct_null_effective_from
FROM raw.sales_targets_raw;


-- Số dòng trùng theo (nhân viên, năm, tháng, phiên bản)
SELECT
    COUNT(*) AS duplicate_keys,
    COALESCE(SUM(so_lan - 1), 0) AS extra_rows
FROM (
    SELECT
        employee_id, year, month, plan_version,
        COUNT(*) AS so_lan
    FROM raw.sales_targets_raw
    GROUP BY employee_id, year, month, plan_version
    HAVING COUNT(*) > 1
) t;


-- Đếm giá trị sai định dạng
SELECT
    COUNT(*) FILTER (WHERE version_date   !~ '^\d{4}-\d{2}-\d{2}$')  AS bad_version_date,
    COUNT(*) FILTER (WHERE effective_from !~ '^\d{4}-\d{2}-\d{2}$')  AS bad_effective_from,
    COUNT(*) FILTER (WHERE effective_to   !~ '^\d{4}-\d{2}-\d{2}$')  AS bad_effective_to,
    COUNT(*) FILTER (WHERE year  !~ '^\d{4}$')                       AS bad_year,
    COUNT(*) FILTER (WHERE month !~ '^(1[0-2]|[1-9])$')              AS bad_month,
    COUNT(*) FILTER (WHERE target_revenue       !~ '^\d+(\.\d+)?$')  AS bad_target_revenue,
    COUNT(*) FILTER (WHERE target_quantity      !~ '^\d+$')          AS bad_target_quantity,
    COUNT(*) FILTER (WHERE target_new_customers !~ '^\d+$')          AS bad_target_new_customers
FROM raw.sales_targets_raw;


-- Liệt kê các giá trị khác nhau của những cột phân loại, để phát hiện cách viết không thống nhất:
SELECT 'plan_version' AS cot, plan_version AS gia_tri, COUNT(*) AS so_dong FROM raw.sales_targets_raw GROUP BY plan_version
UNION ALL
SELECT 'region', region, COUNT(*) FROM raw.sales_targets_raw GROUP BY region
UNION ALL
SELECT 'team', team, COUNT(*) FROM raw.sales_targets_raw GROUP BY team
ORDER BY 1, 3 DESC;


-- Kiểm tra hợp lý: chỉ tiêu bằng 0 và tháng nằm ngoài khoảng hiệu lực của phiên bản
SELECT
    COUNT(*) FILTER (WHERE target_revenue::NUMERIC       = 0) AS doanh_thu_bang_0,
    COUNT(*) FILTER (WHERE target_quantity::NUMERIC      = 0) AS so_luong_bang_0,
    COUNT(*) FILTER (WHERE target_new_customers::NUMERIC = 0) AS khach_moi_bang_0,
    COUNT(*) FILTER (WHERE effective_to::DATE < effective_from::DATE) AS het_han_truoc_hieu_luc,
    COUNT(*) FILTER (WHERE make_date(year::INTEGER, month::INTEGER, 1) < date_trunc('month', effective_from::DATE)
                        OR make_date(year::INTEGER, month::INTEGER, 1) > effective_to::DATE) AS thang_ngoai_hieu_luc
FROM raw.sales_targets_raw
WHERE effective_from ~ '^\d{4}-\d{2}-\d{2}$'
  AND effective_to   ~ '^\d{4}-\d{2}-\d{2}$'
  AND year           ~ '^\d{4}$'
  AND month          ~ '^(1[0-2]|[1-9])$'
  AND target_revenue       ~ '^\d+(\.\d+)?$'
  AND target_quantity      ~ '^\d+$'
  AND target_new_customers ~ '^\d+$';


-- Đối chiếu với employees: mã nhân viên, vùng và team theo cùng phiên bản
SELECT
    t.plan_version,
    COUNT(*)                                        AS so_dong,
    COUNT(*) FILTER (WHERE e.employee_id IS NULL)   AS khong_co_ho_so_cung_phien_ban,
    COUNT(*) FILTER (WHERE t.region <> e.region)    AS khac_vung,
    COUNT(*) FILTER (WHERE t.team   <> e.team)      AS khac_team,
    COUNT(*) FILTER (WHERE e.status = 'Resigned')   AS nhan_vien_da_nghi
FROM raw.sales_targets_raw t
LEFT JOIN raw.employees e
    ON  e.employee_id = t.employee_id
    AND e.version     = t.plan_version
GROUP BY t.plan_version
ORDER BY t.plan_version;


-- 8 nhân viên chỉ có chỉ tiêu v1: tình trạng của họ ở employees v2
SELECT
    e2.status,
    (e2.region <> e1.region) AS da_chuyen_vung,
    COUNT(*) AS so_nhan_vien
FROM (
    SELECT DISTINCT employee_id FROM raw.sales_targets_raw WHERE plan_version = 'v1'
    EXCEPT
    SELECT DISTINCT employee_id FROM raw.sales_targets_raw WHERE plan_version = 'v2'
) only_v1
LEFT JOIN raw.employees e1 ON e1.employee_id = only_v1.employee_id AND e1.version = 'v1'
LEFT JOIN raw.employees e2 ON e2.employee_id = only_v1.employee_id AND e2.version = 'v2'
GROUP BY 1, 2
ORDER BY 1, 2;


-- Nhân viên không có chỉ tiêu nào: chức vụ của họ
SELECT
    e.position,
    COUNT(*) AS so_nhan_vien
FROM raw.employees e
WHERE e.version = 'v1'
  AND NOT EXISTS (SELECT 1 FROM raw.sales_targets_raw t WHERE t.employee_id = e.employee_id)
GROUP BY e.position
ORDER BY e.position;

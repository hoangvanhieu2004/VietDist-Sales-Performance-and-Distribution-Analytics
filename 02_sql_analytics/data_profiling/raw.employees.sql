-- Cấu trúc cột
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'employees'
ORDER BY ordinal_position;


-- Số dòng và % thiếu của cột khóa
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(employee_id), '')    IS NULL) / COUNT(*), 2) AS pct_null_employee_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(full_name), '')      IS NULL) / COUNT(*), 2) AS pct_null_full_name,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(position), '')       IS NULL) / COUNT(*), 2) AS pct_null_position,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(region), '')         IS NULL) / COUNT(*), 2) AS pct_null_region,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(team), '')           IS NULL) / COUNT(*), 2) AS pct_null_team,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(status), '')         IS NULL) / COUNT(*), 2) AS pct_null_status,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(version), '')        IS NULL) / COUNT(*), 2) AS pct_null_version,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(effective_date), '') IS NULL) / COUNT(*), 2) AS pct_null_effective_date
FROM raw.employees;


-- Số dòng trùng theo cặp (mã nhân viên, phiên bản)
SELECT
    COUNT(*) AS duplicate_keys,
    COALESCE(SUM(so_lan - 1), 0) AS extra_rows
FROM (
    SELECT
        employee_id, version,
        COUNT(*) AS so_lan
    FROM raw.employees
    GROUP BY employee_id, version
    HAVING COUNT(*) > 1
) t;


-- Đếm giá trị sai định dạng (bỏ qua ô trống ở resign_date, email, phone)
SELECT
    COUNT(*) FILTER (WHERE date_of_birth  !~ '^\d{4}-\d{2}-\d{2}$')                      AS bad_date_of_birth,
    COUNT(*) FILTER (WHERE join_date      !~ '^\d{4}-\d{2}-\d{2}$')                      AS bad_join_date,
    COUNT(*) FILTER (WHERE effective_date !~ '^\d{4}-\d{2}-\d{2}$')                      AS bad_effective_date,
    COUNT(*) FILTER (WHERE resign_date <> '' AND resign_date !~ '^\d{4}-\d{2}-\d{2}$')   AS bad_resign_date,
    COUNT(*) FILTER (WHERE email <> '' AND email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')       AS bad_email,
    COUNT(*) FILTER (WHERE phone <> '' AND phone !~ '^\d{10,11}$')                       AS bad_phone
FROM raw.employees;


-- Liệt kê các giá trị khác nhau của những cột phân loại, để phát hiện cách viết không thống nhất:
SELECT 'version' AS cot, version AS gia_tri, COUNT(*) AS so_dong FROM raw.employees GROUP BY version
UNION ALL
SELECT 'gender', gender, COUNT(*) FROM raw.employees GROUP BY gender
UNION ALL
SELECT 'position', position, COUNT(*) FROM raw.employees GROUP BY position
UNION ALL
SELECT 'region', region, COUNT(*) FROM raw.employees GROUP BY region
UNION ALL
SELECT 'team', team, COUNT(*) FROM raw.employees GROUP BY team
UNION ALL
SELECT 'status', status, COUNT(*) FROM raw.employees GROUP BY status
ORDER BY 1, 3 DESC;


-- So sánh v1 với v2: bao nhiêu nhân viên thay đổi giữa hai phiên bản
SELECT
    COUNT(*)                                       AS so_nhan_vien,
    COUNT(*) FILTER (WHERE v1.region   <> v2.region)   AS doi_vung,
    COUNT(*) FILTER (WHERE v1.team     <> v2.team)     AS doi_team,
    COUNT(*) FILTER (WHERE v1.position <> v2.position) AS doi_chuc_vu,
    COUNT(*) FILTER (WHERE v1.status   <> v2.status)   AS doi_trang_thai
FROM raw.employees v1
JOIN raw.employees v2
    ON  v1.employee_id = v2.employee_id
    AND v1.version = 'v1'
    AND v2.version = 'v2';


-- Kiểm tra resign_date có khớp với trạng thái không
SELECT
    version,
    status,
    resign_date <> ''  AS co_resign_date,
    transfer_note <> '' AS co_transfer_note,
    COUNT(*) AS so_dong
FROM raw.employees
GROUP BY version, status, resign_date <> '', transfer_note <> ''
ORDER BY version, status, co_resign_date, co_transfer_note;

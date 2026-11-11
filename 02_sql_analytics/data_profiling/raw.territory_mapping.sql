-- Cấu trúc cột
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'territory_mapping'
ORDER BY ordinal_position;


-- Số dòng và % thiếu của cột khóa
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(territory_id), '')   IS NULL) / COUNT(*), 2) AS pct_null_territory_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(employee_id), '')    IS NULL) / COUNT(*), 2) AS pct_null_employee_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(customer_id), '')    IS NULL) / COUNT(*), 2) AS pct_null_customer_id,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(region), '')         IS NULL) / COUNT(*), 2) AS pct_null_region,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(team), '')           IS NULL) / COUNT(*), 2) AS pct_null_team,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(effective_date), '') IS NULL) / COUNT(*), 2) AS pct_null_effective_date,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(expiry_date), '')    IS NULL) / COUNT(*), 2) AS pct_null_expiry_date,
    ROUND(100.0 * COUNT(*) FILTER (WHERE NULLIF(TRIM(version), '')        IS NULL) / COUNT(*), 2) AS pct_null_version
FROM raw.territory_mapping;


-- Số dòng trùng theo mã phân vùng
SELECT
    COUNT(*) AS duplicate_keys,
    COALESCE(SUM(so_lan - 1), 0) AS extra_rows
FROM (
    SELECT
        territory_id,
        COUNT(*) AS so_lan
    FROM raw.territory_mapping
    GROUP BY territory_id
    HAVING COUNT(*) > 1
) t;


-- Đếm giá trị sai định dạng
SELECT
    COUNT(*) FILTER (WHERE effective_date !~ '^\d{4}-\d{2}-\d{2}$') AS bad_effective_date,
    COUNT(*) FILTER (WHERE expiry_date    !~ '^\d{4}-\d{2}-\d{2}$') AS bad_expiry_date
FROM raw.territory_mapping;


-- Liệt kê các giá trị khác nhau của những cột phân loại, để phát hiện cách viết không thống nhất:
SELECT 'region' AS cot, region AS gia_tri, COUNT(*) AS so_dong FROM raw.territory_mapping GROUP BY region
UNION ALL
SELECT 'team', team, COUNT(*) FROM raw.territory_mapping GROUP BY team
UNION ALL
SELECT 'version', version, COUNT(*) FROM raw.territory_mapping GROUP BY version
ORDER BY 1, 3 DESC;


-- Kiểm tra hợp lý: ngày hết hạn trước ngày hiệu lực, và khách hàng bị giao chồng thời gian
SELECT
    (SELECT COUNT(*) FROM raw.territory_mapping
     WHERE expiry_date::DATE < effective_date::DATE)                    AS het_han_truoc_hieu_luc,
    COUNT(*) FILTER (WHERE a.employee_id <> b.employee_id)              AS cap_chong_khac_nhan_vien,
    COUNT(*) FILTER (WHERE a.employee_id =  b.employee_id)              AS cap_chong_cung_nhan_vien,
    COUNT(DISTINCT a.customer_id)                                       AS so_khach_bi_chong
FROM raw.territory_mapping a
JOIN raw.territory_mapping b
    ON  a.customer_id  = b.customer_id
    AND a.territory_id < b.territory_id
    AND a.effective_date::DATE <= b.expiry_date::DATE
    AND b.effective_date::DATE <= a.expiry_date::DATE;


-- Phạm vi theo từng phiên bản
SELECT
    version,
    COUNT(*)                    AS so_dong,
    COUNT(DISTINCT customer_id) AS so_khach,
    COUNT(DISTINCT employee_id) AS so_nhan_vien,
    MIN(effective_date)         AS hieu_luc_som_nhat,
    MAX(effective_date)         AS hieu_luc_muon_nhat,
    MIN(expiry_date)            AS het_han_som_nhat,
    MAX(expiry_date)            AS het_han_muon_nhat
FROM raw.territory_mapping
GROUP BY version
ORDER BY version;


-- Đối chiếu với bảng customers
SELECT
    (SELECT COUNT(*) FROM raw.customers c
     WHERE NOT EXISTS (SELECT 1 FROM raw.territory_mapping t WHERE t.customer_id = c.customer_id)) AS khach_chua_duoc_giao,
    (SELECT COUNT(DISTINCT t.customer_id) FROM raw.territory_mapping t
     WHERE NOT EXISTS (SELECT 1 FROM raw.customers c WHERE c.customer_id = t.customer_id))         AS ma_khach_khong_ton_tai;


-- Chẩn đoán: khách chưa được giao có phải là khách Inactive không
SELECT
    c.status,
    COUNT(*) AS so_khach_chua_duoc_giao
FROM raw.customers c
WHERE NOT EXISTS (SELECT 1 FROM raw.territory_mapping t WHERE t.customer_id = c.customer_id)
GROUP BY c.status;


-- Chẩn đoán: phân vùng (chưa hết hạn) đang giao cho nhân viên đã thay đổi ở employees v2
SELECT
    CASE
        WHEN e2.status = 'Resigned'  THEN 'Nhân viên đã nghỉ việc'
        WHEN e2.region <> e1.region  THEN 'Nhân viên đã chuyển vùng'
        WHEN e2.employee_id IS NULL  THEN 'Không tìm thấy nhân viên'
        ELSE 'Không đổi'
    END AS tinh_trang_nhan_vien,
    COUNT(DISTINCT t.employee_id) AS so_nhan_vien,
    COUNT(*)                      AS so_khach
FROM raw.territory_mapping t
LEFT JOIN raw.employees e1 ON e1.employee_id = t.employee_id AND e1.version = 'v1'
LEFT JOIN raw.employees e2 ON e2.employee_id = t.employee_id AND e2.version = 'v2'
GROUP BY 1
ORDER BY 1;

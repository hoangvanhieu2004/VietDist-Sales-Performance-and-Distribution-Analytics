-- Data quality test cho dwh.dim_employees
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'count: 127 ban ghi (114 nhan vien + 13 thay doi)' AS test,
       ABS(COUNT(*) - 127) AS so_loi
FROM dwh.dim_employees
UNION ALL
SELECT 'unique: employee_sk',
       COUNT(*) - COUNT(DISTINCT employee_sk) FROM dwh.dim_employees
UNION ALL
-- Checkpoint đề bài: nhân viên từng đổi vùng có từ 2 bản ghi trở lên
SELECT 'checkpoint: nhan vien doi vung co tu 2 ban ghi',
       COUNT(*) FROM (
    SELECT v1.employee_id
    FROM staging.stg_employees v1
    JOIN staging.stg_employees v2
        ON v2.employee_id = v1.employee_id AND v1.version = 'v1' AND v2.version = 'v2'
    WHERE v1.region <> v2.region
) doi_vung
WHERE (SELECT COUNT(*) FROM dwh.dim_employees d WHERE d.employee_id = doi_vung.employee_id) < 2
UNION ALL
-- Checkpoint đề bài: mỗi nhân viên đúng 1 bản ghi is_current, và đó là bản ghi mới nhất
SELECT 'checkpoint: dung 1 is_current moi nhan vien, la ban ghi moi nhat',
       COUNT(*) FROM (
    SELECT employee_id
    FROM dwh.dim_employees
    GROUP BY employee_id
    HAVING COUNT(*) FILTER (WHERE is_current) <> 1
        OR MAX(effective_from) <> MAX(effective_from) FILTER (WHERE is_current)
) x
UNION ALL
-- Các giai đoạn nối tiếp: ngày bắt đầu giai đoạn sau = ngày kết thúc giai đoạn trước + 1
SELECT 'continuity: khong chong, khong ho giua cac giai doan',
       COUNT(*) FROM (
    SELECT effective_to,
           LEAD(effective_from) OVER (PARTITION BY employee_id ORDER BY effective_from) AS next_from
    FROM dwh.dim_employees
) x
WHERE next_from IS NOT NULL AND next_from <> effective_to + 1
UNION ALL
SELECT 'range: effective_to >= effective_from',
       COUNT(*) FROM dwh.dim_employees WHERE effective_to < effective_from
UNION ALL
SELECT 'completeness: moi nhan vien trong stg_employees deu co trong dim',
       COUNT(*) FROM (SELECT DISTINCT employee_id FROM staging.stg_employees) s
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_employees d WHERE d.employee_id = s.employee_id);

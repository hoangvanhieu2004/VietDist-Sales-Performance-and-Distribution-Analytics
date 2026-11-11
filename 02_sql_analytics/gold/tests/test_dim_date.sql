-- Data quality test cho dwh.dim_date
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'count: 1826 ngay tu 2022-01-01 den 2026-12-31' AS test,
       ABS(COUNT(*) - 1826) AS so_loi
FROM dwh.dim_date
UNION ALL
-- Không thiếu ngày: số dòng bằng số ngày giữa ngày đầu và ngày cuối
SELECT 'no_gap: khong thieu ngay',
       ABS(COUNT(*) - (MAX(full_date) - MIN(full_date) + 1)) FROM dwh.dim_date
UNION ALL
SELECT 'unique: date_key, full_date',
       (COUNT(*) - COUNT(DISTINCT date_key)) + (COUNT(*) - COUNT(DISTINCT full_date)) FROM dwh.dim_date
UNION ALL
-- Checkpoint đề bài và ranh giới năm tài chính
SELECT 'fiscal_year: 2023-10-01 = FY2023',
       COUNT(*) FROM dwh.dim_date WHERE full_date = '2023-10-01' AND fiscal_year <> 2023
UNION ALL
SELECT 'fiscal_year: 2024-01-01 = FY2023',
       COUNT(*) FROM dwh.dim_date WHERE full_date = '2024-01-01' AND fiscal_year <> 2023
UNION ALL
SELECT 'fiscal_year: 2024-08-31 = FY2023, 2024-09-01 = FY2024',
       COUNT(*) FROM dwh.dim_date
WHERE (full_date = '2024-08-31' AND fiscal_year <> 2023)
   OR (full_date = '2024-09-01' AND fiscal_year <> 2024)
UNION ALL
SELECT 'fiscal_month: thang 9 = 1, thang 1 = 5, thang 8 = 12',
       COUNT(*) FROM dwh.dim_date
WHERE (month = 9 AND fiscal_month <> 1)
   OR (month = 1 AND fiscal_month <> 5)
   OR (month = 8 AND fiscal_month <> 12)
UNION ALL
SELECT 'range: fiscal_month 1-12, fiscal_quarter 1-4',
       COUNT(*) FROM dwh.dim_date
WHERE fiscal_month NOT BETWEEN 1 AND 12 OR fiscal_quarter NOT BETWEEN 1 AND 4
UNION ALL
SELECT 'leap_day: dung 1 ngay 29/02 (2024)',
       ABS(COUNT(*) FILTER (WHERE is_leap_day) - 1) FROM dwh.dim_date;

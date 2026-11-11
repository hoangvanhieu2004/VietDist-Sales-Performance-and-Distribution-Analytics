-- Xóa bảng cũ để chạy lại được nhiều lần
DROP TABLE IF EXISTS dwh.dim_date;

CREATE TABLE dwh.dim_date AS
WITH days AS (
    -- Sinh mỗi ngày một dòng từ 2022 đến 2026 (giả định A-23)
    SELECT d::DATE AS full_date
    FROM generate_series('2022-01-01'::DATE, '2026-12-31'::DATE, INTERVAL '1 day') AS g(d)
),
parts AS (
    SELECT
        full_date,
        EXTRACT(YEAR    FROM full_date)::INTEGER AS year,
        EXTRACT(MONTH   FROM full_date)::INTEGER AS month,
        EXTRACT(DAY     FROM full_date)::INTEGER AS day_of_month,
        EXTRACT(ISODOW  FROM full_date)::INTEGER AS day_of_week   -- 1 = Thứ Hai ... 7 = Chủ Nhật
    FROM days
)
SELECT
    TO_CHAR(full_date, 'YYYYMMDD')::INTEGER         AS date_key,        -- khóa dạng số: 20240115
    full_date,
    day_of_month,
    day_of_week,
    CASE day_of_week
        WHEN 1 THEN 'Thứ Hai'  WHEN 2 THEN 'Thứ Ba'  WHEN 3 THEN 'Thứ Tư'
        WHEN 4 THEN 'Thứ Năm'  WHEN 5 THEN 'Thứ Sáu' WHEN 6 THEN 'Thứ Bảy'
        ELSE 'Chủ Nhật'
    END                                             AS day_name,
    (day_of_week IN (6, 7))                         AS is_weekend,
    EXTRACT(WEEK FROM full_date)::INTEGER           AS iso_week,
    month,
    EXTRACT(QUARTER FROM full_date)::INTEGER        AS quarter,
    year,
    TO_CHAR(full_date, 'YYYY-MM')                   AS year_month,
    -- Năm tài chính: 01/09 đến 31/08, đặt tên theo năm bắt đầu (giả định A-22)
    CASE WHEN month >= 9 THEN year ELSE year - 1 END AS fiscal_year,
    (month + 3) % 12 + 1                            AS fiscal_month,   -- tháng 9 = 1, tháng 8 = 12
    ((month + 3) % 12) / 3 + 1                      AS fiscal_quarter,
    (month = 2 AND day_of_month = 29)               AS is_leap_day      -- BRD: bỏ 29/02 khi so cùng kỳ
FROM parts;

-- Khóa chính
ALTER TABLE dwh.dim_date ADD PRIMARY KEY (date_key);

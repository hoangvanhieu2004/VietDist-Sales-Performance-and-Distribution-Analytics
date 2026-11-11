-- View dim_employees theo SCD Type 2: mỗi nhân viên một bản ghi cho mỗi giai đoạn có thông tin khác nhau
DROP VIEW IF EXISTS dwh.dim_employees;

CREATE VIEW dwh.dim_employees AS
WITH snapshots AS (
    -- Mỗi ảnh chụp (v1, v2) của nhân viên, kèm thông tin của ảnh chụp liền trước
    SELECT
        e.*,
        LAG(region)   OVER w AS prev_region,
        LAG(team)     OVER w AS prev_team,
        LAG(position) OVER w AS prev_position,
        LAG(status)   OVER w AS prev_status
    FROM staging.stg_employees e
    WINDOW w AS (PARTITION BY employee_id ORDER BY effective_date)
),
changes AS (
    -- Chỉ giữ ảnh chụp đầu tiên và các ảnh chụp có thay đổi (giả định A-13)
    SELECT *
    FROM snapshots
    WHERE prev_region IS NULL                    -- ảnh chụp đầu tiên
       OR region   IS DISTINCT FROM prev_region
       OR team     IS DISTINCT FROM prev_team
       OR position IS DISTINCT FROM prev_position
       OR status   IS DISTINCT FROM prev_status
)
SELECT
    employee_id || '_' || TO_CHAR(effective_date, 'YYYYMMDD') AS employee_sk,  -- khóa thay thế
    employee_id,
    full_name,
    gender,
    date_of_birth,
    join_date,
    position,
    region,
    team,
    status,
    resign_date,
    transfer_note,
    effective_date AS effective_from,
    COALESCE(
        LEAD(effective_date) OVER (PARTITION BY employee_id ORDER BY effective_date) - 1,
        DATE '9999-12-31'                        -- quy ước: chưa kết thúc
    ) AS effective_to,
    (LEAD(effective_date) OVER (PARTITION BY employee_id ORDER BY effective_date) IS NULL) AS is_current,
    version AS source_version
FROM changes;

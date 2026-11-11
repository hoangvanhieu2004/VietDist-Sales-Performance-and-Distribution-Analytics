-- View dim_distributors theo cấu trúc SCD Type 2 (giả định A-14)
-- Nguồn chỉ có một ảnh chụp nên mỗi nhà phân phối hiện có một bản ghi (hạn chế L-05)
-- Không đưa số điện thoại, email, người liên hệ, mã số thuế sang Gold (vẫn có ở staging nếu cần)
DROP VIEW IF EXISTS dwh.dim_distributors;

CREATE VIEW dwh.dim_distributors AS
SELECT
    distributor_id || '_' || TO_CHAR(join_date, 'YYYYMMDD') AS distributor_sk,   -- khóa thay thế
    distributor_id,
    distributor_name,
    tier,
    channel,
    province,
    region,
    status,
    join_date,
    credit_limit,
    assigned_supervisor_id,
    join_date            AS effective_from,
    DATE '9999-12-31'    AS effective_to,      -- quy ước: chưa kết thúc
    TRUE                 AS is_current
FROM staging.stg_distributors;

-- Xóa bảng cũ để chạy lại được nhiều lần
DROP TABLE IF EXISTS staging.stg_promotion_program;

CREATE TABLE staging.stg_promotion_program AS
WITH ranked AS (
    -- Đánh số các dòng trùng khóa, dòng nạp mới nhất được số 1
    -- (Bronze có 80 dòng do nạp 2 lần, sau bước này còn 40)
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY TRIM(promotion_id) ORDER BY _ingested_at DESC) AS rn
    FROM raw.promotion_program
)
SELECT
    TRIM(promotion_id)                                   AS promotion_id,
    TRIM(promotion_name)                                 AS promotion_name,
    TRIM(promotion_type)                                 AS promotion_type,
    TRIM(target_channel)                                 AS target_channel,   -- 'All' = mọi kênh
    TRIM(target_region)                                  AS target_region,    -- 'All' = mọi vùng
    start_date::DATE                                     AS start_date,
    end_date::DATE                                       AS end_date,
    TRIM(applicable_products)                            AS applicable_products,
    string_to_array(TRIM(applicable_products), '|')      AS applicable_product_ids,  -- tách thành mảng mã sản phẩm
    discount_pct::NUMERIC(5, 2)                          AS discount_pct,
    min_order_quantity::INTEGER                          AS min_order_quantity,
    budget_vnd::NUMERIC(18, 2)                           AS budget_vnd,
    actual_cost_vnd::NUMERIC(18, 2)                      AS actual_cost_vnd,
    TRIM(status)                                         AS status,
    TRIM(created_by)                                     AS created_by,
    _source_file,
    _batch_id,
    _ingested_at
FROM ranked
WHERE rn = 1                                                      -- chỉ giữ 1 dòng mỗi khóa
  AND NULLIF(NULLIF(TRIM(promotion_id), ''), 'nan') IS NOT NULL;   -- bỏ dòng thiếu khóa

-- Khóa chính: database sẽ báo lỗi nếu còn trùng hoặc thiếu
ALTER TABLE staging.stg_promotion_program ADD PRIMARY KEY (promotion_id);

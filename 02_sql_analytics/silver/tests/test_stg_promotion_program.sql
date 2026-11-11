-- Data quality test cho staging.stg_promotion_program
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'not_null: promotion_id, promotion_name, promotion_type, start_date, end_date, applicable_product_ids, status' AS test,
       COUNT(*) AS so_loi
FROM staging.stg_promotion_program
WHERE promotion_id IS NULL OR promotion_name IS NULL OR promotion_type IS NULL OR start_date IS NULL
   OR end_date IS NULL OR applicable_product_ids IS NULL OR status IS NULL
UNION ALL
SELECT 'unique: promotion_id',
       COUNT(*) - COUNT(DISTINCT promotion_id) FROM staging.stg_promotion_program
UNION ALL
SELECT 'accepted_values: promotion_type',
       COUNT(*) FROM staging.stg_promotion_program
WHERE promotion_type NOT IN ('Giảm giá trực tiếp', 'Tích điểm đổi quà', 'Tặng hàng kèm',
                             'Combo khuyến mãi', 'Chiết khấu theo sản lượng')
UNION ALL
SELECT 'accepted_values: status',
       COUNT(*) FROM staging.stg_promotion_program
WHERE status NOT IN ('Completed', 'Active', 'Planned')
UNION ALL
SELECT 'accepted_values: target_channel',
       COUNT(*) FROM staging.stg_promotion_program
WHERE target_channel NOT IN ('Traditional Trade', 'Modern Trade', 'E-commerce', 'All')
UNION ALL
SELECT 'accepted_values: target_region',
       COUNT(*) FROM staging.stg_promotion_program
WHERE target_region NOT IN ('Miền Bắc', 'Miền Trung', 'Miền Nam', 'All')
UNION ALL
SELECT 'range: end_date >= start_date',
       COUNT(*) FROM staging.stg_promotion_program WHERE end_date < start_date
UNION ALL
SELECT 'range: 0 <= discount_pct <= 100',
       COUNT(*) FROM staging.stg_promotion_program WHERE discount_pct < 0 OR discount_pct > 100
UNION ALL
SELECT 'range: budget_vnd >= 0',
       COUNT(*) FROM staging.stg_promotion_program WHERE budget_vnd < 0
UNION ALL
-- Dàn mảng mã sản phẩm ra từng dòng rồi kiểm tra mã có trong stg_products
SELECT 'relationships: applicable_product_ids -> stg_products',
       COUNT(*) FROM staging.stg_promotion_program p
CROSS JOIN LATERAL unnest(p.applicable_product_ids) AS x(product_id)
WHERE NOT EXISTS (SELECT 1 FROM staging.stg_products s WHERE s.product_id = x.product_id)
UNION ALL
SELECT 'reconcile: so dong bang so ma khac nhau o raw.promotion_program',
       ABS((SELECT COUNT(*) FROM staging.stg_promotion_program)
         - (SELECT COUNT(DISTINCT TRIM(promotion_id)) FROM raw.promotion_program));

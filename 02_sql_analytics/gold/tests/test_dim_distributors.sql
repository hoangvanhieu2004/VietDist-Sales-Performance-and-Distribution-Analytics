-- Data quality test cho dwh.dim_distributors
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'completeness: dim_distributors = stg_distributors' AS test,
       ABS((SELECT COUNT(*) FROM dwh.dim_distributors) - (SELECT COUNT(*) FROM staging.stg_distributors)) AS so_loi
UNION ALL
SELECT 'unique: distributor_sk',
       COUNT(*) - COUNT(DISTINCT distributor_sk) FROM dwh.dim_distributors
UNION ALL
SELECT 'one_current: dung 1 is_current moi nha phan phoi',
       COUNT(*) FROM (
    SELECT distributor_id FROM dwh.dim_distributors
    GROUP BY distributor_id
    HAVING COUNT(*) FILTER (WHERE is_current) <> 1
) x
UNION ALL
-- Mỗi đơn hàng phải nối được đúng 1 bản ghi dim theo thời gian
SELECT 'temporal_join: moi don tim thay dung 1 ban ghi dim theo order_date',
       COUNT(*) FROM (
    SELECT o.order_id, o.product_id
    FROM staging.stg_distributor_orders o
    LEFT JOIN dwh.dim_distributors d
        ON  d.distributor_id = o.distributor_id
        AND o.order_date BETWEEN d.effective_from AND d.effective_to
    GROUP BY o.order_id, o.product_id
    HAVING COUNT(d.distributor_sk) <> 1
) x;

-- Data quality test cho dwh.dim_customers và dwh.dim_products
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'completeness: dim_customers = stg_customers' AS test,
       ABS((SELECT COUNT(*) FROM dwh.dim_customers) - (SELECT COUNT(*) FROM staging.stg_customers)) AS so_loi
UNION ALL
SELECT 'completeness: dim_products = stg_products',
       ABS((SELECT COUNT(*) FROM dwh.dim_products) - (SELECT COUNT(*) FROM staging.stg_products))
UNION ALL
SELECT 'unique: customer_id',
       COUNT(*) - COUNT(DISTINCT customer_id) FROM dwh.dim_customers
UNION ALL
SELECT 'unique: product_id',
       COUNT(*) - COUNT(DISTINCT product_id) FROM dwh.dim_products
UNION ALL
SELECT 'accepted_values: loyalty_tier',
       COUNT(*) FROM dwh.dim_customers
WHERE loyalty_tier NOT IN ('Vàng', 'Bạc', 'Đồng', 'Chưa mua')
UNION ALL
SELECT 'consistency: Chua mua khi va chi khi revenue_2024 = 0',
       COUNT(*) FROM dwh.dim_customers
WHERE (loyalty_tier = 'Chưa mua') <> (revenue_2024 = 0)
UNION ALL
SELECT 'range: 0 <= gross_margin_pct <= 100',
       COUNT(*) FROM dwh.dim_products WHERE gross_margin_pct < 0 OR gross_margin_pct > 100
UNION ALL
-- Theo dõi: hạng Vàng chiếm khoảng 20% số khách đã mua (cho phép 18% đến 22%)
SELECT 'monitor: hang Vang khoang 20% khach da mua',
       CASE WHEN 1.0 * COUNT(*) FILTER (WHERE loyalty_tier = 'Vàng')
                 / NULLIF(COUNT(*) FILTER (WHERE loyalty_tier <> 'Chưa mua'), 0)
                 BETWEEN 0.18 AND 0.22
            THEN 0 ELSE 1 END
FROM dwh.dim_customers;


-- Phân bổ hạng khách hàng (để đọc, không phải test)
SELECT
    loyalty_tier,
    COUNT(*)                                                AS so_khach,
    ROUND(SUM(revenue_2024) / 1e9, 2)                       AS doanh_thu_ty_dong,
    ROUND(100.0 * SUM(revenue_2024) / SUM(SUM(revenue_2024)) OVER (), 1) AS ty_trong_doanh_thu_pct
FROM dwh.dim_customers
GROUP BY loyalty_tier
ORDER BY MIN(CASE loyalty_tier WHEN 'Vàng' THEN 1 WHEN 'Bạc' THEN 2 WHEN 'Đồng' THEN 3 ELSE 4 END);

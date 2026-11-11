-- View dim_customers theo SCD Type 1: chỉ giữ thông tin hiện tại, kèm hạng khách hàng
-- Không đưa số điện thoại, địa chỉ, mã số thuế sang Gold (vẫn có ở staging nếu cần)
DROP VIEW IF EXISTS dwh.dim_customers;

CREATE VIEW dwh.dim_customers AS
WITH revenue AS (
    -- Doanh thu 2024 của mỗi khách, chỉ đơn đã giao (giả định A-01)
    SELECT customer_id, SUM(net_amount) AS revenue_2024
    FROM staging.stg_sales_transactions
    WHERE delivery_status = 'Delivered'
    GROUP BY customer_id
),
ranked AS (
    -- Xếp hạng phần trăm: 0 = cao nhất, 1 = thấp nhất
    SELECT customer_id, revenue_2024,
           PERCENT_RANK() OVER (ORDER BY revenue_2024 DESC) AS pct_rank
    FROM revenue
)
SELECT
    c.customer_id,
    c.customer_name,
    c.customer_type,
    c.channel,
    c.province,
    c.region,
    c.status,
    c.join_date,
    c.credit_limit,
    COALESCE(r.revenue_2024, 0) AS revenue_2024,
    CASE                                         -- hạng khách hàng (giả định A-26)
        WHEN r.customer_id IS NULL THEN 'Chưa mua'
        WHEN r.pct_rank < 0.2      THEN 'Vàng'
        WHEN r.pct_rank < 0.5      THEN 'Bạc'
        ELSE 'Đồng'
    END AS loyalty_tier
FROM staging.stg_customers c
LEFT JOIN ranked r ON r.customer_id = c.customer_id;

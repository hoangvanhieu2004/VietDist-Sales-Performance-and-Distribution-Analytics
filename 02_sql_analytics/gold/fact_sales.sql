-- View fact_sales: mỗi dòng là một sản phẩm trong một đơn hàng (grain: 1 line item)
-- Giữ mọi dòng, kể cả Cancelled và Delivering. Doanh thu thực tế nằm ở cột revenue_amount
DROP VIEW IF EXISTS dwh.fact_sales;

CREATE VIEW dwh.fact_sales AS
WITH resign AS (
    -- Ngày nghỉ việc của mỗi nhân viên (nếu có), lấy từ hồ sơ nhân viên
    SELECT employee_id, MAX(resign_date) AS resign_date
    FROM staging.stg_employees
    GROUP BY employee_id
)
SELECT
    s.order_id,
    s.product_id,
    TO_CHAR(s.order_date, 'YYYYMMDD')::INTEGER     AS date_key,       -- nối với dim_date
    s.order_date,
    s.customer_id,                                                    -- nối với dim_customers
    e.employee_sk,                                                    -- nối với dim_employees theo thời gian
    s.employee_id,
    s.region,
    s.province,
    s.channel,
    s.quantity,
    s.unit_price,
    s.discount_amount,
    s.gross_amount,
    s.net_amount,
    s.delivery_status,
    s.payment_method,
    s.payment_status,
    (s.delivery_status = 'Delivered')              AS is_delivered,
    CASE WHEN s.delivery_status = 'Delivered'
         THEN s.net_amount ELSE 0 END              AS revenue_amount,  -- doanh thu thực tế (giả định A-01)
    s.quantity * p.cost_price                      AS cost_amount,     -- giá vốn theo giá hiện tại (hạn chế L-12)
    COALESCE(s.order_date > r.resign_date, FALSE)  AS is_after_resign  -- ghi sau ngày nghỉ (giả định A-25)
FROM staging.stg_sales_transactions s
LEFT JOIN dwh.dim_employees e
    ON  e.employee_id = s.employee_id
    AND s.order_date BETWEEN e.effective_from AND e.effective_to          -- nối theo thời gian (SCD2)
LEFT JOIN staging.stg_products p ON p.product_id = s.product_id
LEFT JOIN resign r ON r.employee_id = s.employee_id;

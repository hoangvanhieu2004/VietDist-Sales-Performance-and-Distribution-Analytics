-- View fact_returns: mỗi dòng là một phiếu trả hàng
-- Doanh thu thuần = tổng fact_sales.revenue_amount trừ tổng fact_returns.deducted_amount
DROP VIEW IF EXISTS dwh.fact_returns;

CREATE VIEW dwh.fact_returns AS
SELECT
    r.return_id,
    r.original_order_id,
    r.product_id,
    TO_CHAR(r.return_date, 'YYYYMMDD')::INTEGER AS date_key,         -- tính vào kỳ theo ngày trả (A-02)
    r.return_date,
    r.customer_id,
    e.employee_sk,                                                   -- nối theo ngày trả
    r.employee_id,
    r.region,
    r.return_quantity,
    r.unit_price,
    r.return_amount,
    r.return_reason,
    r.status,
    (r.status = 'Đã xử lý')                     AS is_deducted,
    CASE WHEN r.status = 'Đã xử lý'
         THEN r.return_amount ELSE 0 END        AS deducted_amount   -- số tiền trừ doanh thu (A-02)
FROM staging.stg_return_transactions r
LEFT JOIN dwh.dim_employees e
    ON  e.employee_id = r.employee_id
    AND r.return_date BETWEEN e.effective_from AND e.effective_to;

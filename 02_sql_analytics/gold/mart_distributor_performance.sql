-- View mart_distributor_performance: hiệu suất nhà phân phối theo tháng
-- Mỗi nhà phân phối có đủ mọi tháng, kể cả tháng không đặt hàng (ghi 0)
DROP VIEW IF EXISTS dwh.mart_distributor_performance;

CREATE VIEW dwh.mart_distributor_performance AS
WITH months AS (
    -- Các tháng có dữ liệu đơn hàng
    SELECT DISTINCT DATE_TRUNC('month', order_date)::DATE AS month_start
    FROM staging.stg_distributor_orders
),
grid AS (
    -- Mỗi nhà phân phối x mỗi tháng, để tháng không đặt hàng vẫn hiện số 0
    SELECT d.distributor_sk, d.distributor_id, m.month_start
    FROM dwh.dim_distributors d
    CROSS JOIN months m
),
orders AS (
    -- Số liệu theo tháng, loại đơn Cancelled (giả định A-16)
    SELECT
        distributor_id,
        DATE_TRUNC('month', order_date)::DATE                       AS month_start,
        COUNT(DISTINCT order_id)                                    AS total_orders,
        SUM(gross_amount)                                           AS total_order_value,   -- A-18
        SUM(qty_ordered)                                            AS qty_ordered,
        SUM(qty_delivered)                                          AS qty_delivered,
        SUM(CASE WHEN is_ontime THEN qty_delivered ELSE 0 END)      AS qty_delivered_ontime, -- A-15
        COUNT(*)                                                    AS order_lines,
        COUNT(*) FILTER (WHERE is_ontime)                           AS ontime_lines
    FROM staging.stg_distributor_orders
    WHERE delivery_status <> 'Cancelled'
    GROUP BY 1, 2
),
cancelled AS (
    SELECT distributor_id,
           DATE_TRUNC('month', order_date)::DATE AS month_start,
           COUNT(*) AS cancelled_lines
    FROM staging.stg_distributor_orders
    WHERE delivery_status = 'Cancelled'
    GROUP BY 1, 2
),
last_order AS (
    -- Ngày đặt hàng gần nhất (không tính đơn Cancelled), cho cảnh báo 30 ngày
    SELECT distributor_id, MAX(order_date) AS last_order_date
    FROM staging.stg_distributor_orders
    WHERE delivery_status <> 'Cancelled'
    GROUP BY distributor_id
)
SELECT
    g.distributor_sk,
    g.distributor_id,
    d.distributor_name,
    d.tier,
    d.channel,
    d.region,
    EXTRACT(YEAR  FROM g.month_start)::INTEGER                     AS year,
    EXTRACT(MONTH FROM g.month_start)::INTEGER                     AS month,
    TO_CHAR(g.month_start, 'YYYYMMDD')::INTEGER                    AS date_key,
    COALESCE(o.total_orders, 0)                                    AS total_orders,
    COALESCE(o.total_order_value, 0)                               AS total_order_value,
    COALESCE(o.qty_ordered, 0)                                     AS qty_ordered,
    COALESCE(o.qty_delivered, 0)                                   AS qty_delivered,
    COALESCE(o.qty_delivered_ontime, 0)                            AS qty_delivered_ontime,
    COALESCE(c.cancelled_lines, 0)                                 AS cancelled_lines,
    ROUND(o.qty_delivered_ontime::NUMERIC / NULLIF(o.qty_ordered, 0) * 100, 2) AS fill_rate_pct,  -- A-17
    ROUND(o.ontime_lines::NUMERIC / NULLIF(o.order_lines, 0) * 100, 2)        AS ontime_rate_pct,
    -- Cảnh báo không đặt hàng quá 30 ngày, tính tại ngày tham chiếu 2024-12-31 (A-05)
    -- Giá trị giống nhau ở mọi tháng của cùng nhà phân phối: chỉ đếm theo nhà phân phối, không cộng theo tháng
    l.last_order_date,
    (DATE '2024-12-31' - l.last_order_date)                        AS days_since_last_order,
    (l.last_order_date IS NULL
     OR DATE '2024-12-31' - l.last_order_date > 30)                AS is_inactive_alert
FROM grid g
JOIN dwh.dim_distributors d ON d.distributor_sk = g.distributor_sk
LEFT JOIN orders o      ON o.distributor_id = g.distributor_id AND o.month_start = g.month_start
LEFT JOIN cancelled c   ON c.distributor_id = g.distributor_id AND c.month_start = g.month_start
LEFT JOIN last_order l  ON l.distributor_id = g.distributor_id;

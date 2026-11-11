-- Data quality test cho dwh.mart_distributor_performance
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'grid: so dong = so nha phan phoi x so thang' AS test,
       ABS((SELECT COUNT(*) FROM dwh.mart_distributor_performance)
         - (SELECT COUNT(*) FROM dwh.dim_distributors)
           * (SELECT COUNT(DISTINCT DATE_TRUNC('month', order_date)) FROM staging.stg_distributor_orders)) AS so_loi
UNION ALL
SELECT 'unique: (distributor_id, year, month)',
       COUNT(*) - COUNT(DISTINCT (distributor_id, year, month)) FROM dwh.mart_distributor_performance
UNION ALL
SELECT 'reconcile: total_order_value = gross_amount don khong Cancelled',
       ABS((SELECT SUM(total_order_value) FROM dwh.mart_distributor_performance)
         - (SELECT SUM(gross_amount) FROM staging.stg_distributor_orders WHERE delivery_status <> 'Cancelled'))
UNION ALL
SELECT 'reconcile: cancelled_lines = so dong Cancelled o Silver',
       ABS((SELECT SUM(cancelled_lines) FROM dwh.mart_distributor_performance)
         - (SELECT COUNT(*) FROM staging.stg_distributor_orders WHERE delivery_status = 'Cancelled'))
UNION ALL
SELECT 'no_divide_by_zero: fill_rate_pct trong khi qty_ordered = 0',
       COUNT(*) FROM dwh.mart_distributor_performance
WHERE qty_ordered = 0 AND fill_rate_pct IS NOT NULL
UNION ALL
SELECT 'range: fill_rate_pct, ontime_rate_pct tu 0 den 100',
       COUNT(*) FROM dwh.mart_distributor_performance
WHERE fill_rate_pct NOT BETWEEN 0 AND 100 OR ontime_rate_pct NOT BETWEEN 0 AND 100;


-- Tóm tắt theo kênh cả năm (để đọc, không phải test)
SELECT
    channel,
    COUNT(DISTINCT distributor_id)                                         AS so_npp,
    SUM(total_orders)                                                      AS tong_don,
    ROUND(SUM(total_order_value) / 1e9, 2)                                 AS gia_tri_dat_ty,
    ROUND(SUM(qty_delivered_ontime)::NUMERIC / NULLIF(SUM(qty_ordered), 0) * 100, 1) AS fill_rate_pct,
    ROUND(SUM(qty_delivered)::NUMERIC / NULLIF(SUM(qty_ordered), 0) * 100, 1)        AS ty_le_giao_pct,
    COUNT(DISTINCT distributor_id) FILTER (WHERE is_inactive_alert)        AS so_npp_canh_bao_30_ngay
FROM dwh.mart_distributor_performance
GROUP BY channel
ORDER BY channel;

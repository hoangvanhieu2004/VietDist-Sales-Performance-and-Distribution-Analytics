-- Data quality test cho staging.stg_return_transactions
-- Mỗi dòng kết quả là một test. so_loi = 0 là đạt.
SELECT 'not_null: return_id, original_order_id, product_id, return_date, customer_id, return_quantity, return_amount, status' AS test,
       COUNT(*) AS so_loi
FROM staging.stg_return_transactions
WHERE return_id IS NULL OR original_order_id IS NULL OR product_id IS NULL OR return_date IS NULL
   OR customer_id IS NULL OR return_quantity IS NULL OR return_amount IS NULL OR status IS NULL
UNION ALL
SELECT 'unique: return_id',
       COUNT(*) - COUNT(DISTINCT return_id) FROM staging.stg_return_transactions
UNION ALL
SELECT 'accepted_values: status',
       COUNT(*) FROM staging.stg_return_transactions
WHERE status NOT IN ('Đã xử lý', 'Đang xử lý', 'Từ chối')
UNION ALL
SELECT 'accepted_values: return_reason',
       COUNT(*) FROM staging.stg_return_transactions
WHERE return_reason NOT IN ('Khách từ chối nhận', 'Hàng vỡ vận chuyển', 'Hàng hết hạn',
                            'Hàng lỗi', 'Không đúng đơn hàng', 'Sai sản phẩm')
UNION ALL
SELECT 'accepted_values: region',
       COUNT(*) FROM staging.stg_return_transactions
WHERE region NOT IN ('Miền Bắc', 'Miền Trung', 'Miền Nam')
UNION ALL
SELECT 'range: return_quantity > 0',
       COUNT(*) FROM staging.stg_return_transactions WHERE return_quantity <= 0
UNION ALL
SELECT 'range: return_amount = return_quantity * unit_price',
       COUNT(*) FROM staging.stg_return_transactions
WHERE ABS(return_amount - return_quantity * unit_price) > 1
UNION ALL
-- Mỗi phiếu trả phải tìm thấy dòng đơn gốc trong stg_sales_transactions
SELECT 'relationships: (original_order_id, product_id) -> stg_sales_transactions',
       COUNT(*) FROM staging.stg_return_transactions r
WHERE NOT EXISTS (
    SELECT 1 FROM staging.stg_sales_transactions s
    WHERE s.order_id = r.original_order_id AND s.product_id = r.product_id
)
UNION ALL
SELECT 'reconcile: so dong bang raw.return_transactions',
       ABS((SELECT COUNT(*) FROM staging.stg_return_transactions)
         - (SELECT COUNT(DISTINCT TRIM(return_id)) FROM raw.return_transactions));

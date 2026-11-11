-- View dim_products theo SCD Type 1: chỉ giữ thông tin hiện tại
DROP VIEW IF EXISTS dwh.dim_products;

CREATE VIEW dwh.dim_products AS
SELECT
    product_id,
    product_name,
    category,
    sub_category,
    unit,
    unit_price,
    cost_price,
    ROUND((unit_price - cost_price) / unit_price * 100, 2) AS gross_margin_pct,   -- biên lợi nhuận gộp (%)
    weight_gram,
    status,
    launch_date
FROM staging.stg_products;

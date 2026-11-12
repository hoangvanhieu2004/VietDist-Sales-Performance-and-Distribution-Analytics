# Từ điển dữ liệu: tầng Gold

Tài liệu này mô tả các bảng và view trong schema `dwh` của database `vietdist_dw1`, nơi Power BI đọc dữ liệu. Dữ liệu hiện có là năm 2024 (01/01 đến 31/12).

- `dim_date` là bảng. Mọi đối tượng khác là view trên schema `staging`, nên luôn phản ánh dữ liệu Silver mới nhất.
- Code nằm ở `02_sql_analytics/gold/`, test ở `02_sql_analytics/gold/tests/`.
- Các mã giả định (A-xx) và hạn chế (L-xx) tham chiếu `docs/assumptions_log.md`.

## Tổng quan

| Đối tượng | Loại | Mỗi dòng là | Khóa | Số dòng |
|---|---|---|---|---|
| `dim_date` | Dimension (bảng) | Một ngày, 2022 đến 2026 | `date_key` | 1.826 |
| `dim_employees` | Dimension, SCD Type 2 | Một giai đoạn của một nhân viên | `employee_sk` | 127 |
| `dim_customers` | Dimension, SCD Type 1 | Một khách hàng | `customer_id` | 2.000 |
| `dim_products` | Dimension, SCD Type 1 | Một sản phẩm | `product_id` | 100 |
| `dim_distributors` | Dimension, cấu trúc SCD Type 2 | Một giai đoạn của một nhà phân phối | `distributor_sk` | 138 |
| `fact_sales` | Fact | Một sản phẩm trong một đơn bán hàng | `order_id`, `product_id` | 119.101 |
| `fact_targets` | Fact (temporal) | Chỉ tiêu của một nhân viên, một tháng, một phiên bản | `employee_id`, `year`, `month`, `plan_version` | 1.950 |
| `fact_returns` | Fact | Một phiếu trả hàng | `return_id` | 3.665 |
| `mart_sales_vs_target` | Mart | Thực tế so chỉ tiêu của một nhân viên, một tháng, một phiên bản | `employee_id`, `year`, `month`, `plan_version` | 1.956 |
| `mart_distributor_performance` | Mart | Hiệu suất của một nhà phân phối trong một tháng | `distributor_id`, `year`, `month` | 1.656 |

## Quan hệ cho Power BI

Tất cả là quan hệ nhiều-một (bảng bên trái nhiều dòng, dimension một dòng), lọc một chiều từ dimension sang fact.

| Từ | Đến |
|---|---|
| `fact_sales.date_key`, `fact_returns.date_key`, `fact_targets.date_key`, `mart_sales_vs_target.date_key`, `mart_distributor_performance.date_key` | `dim_date.date_key` |
| `fact_sales.employee_sk`, `fact_returns.employee_sk`, `fact_targets.employee_sk`, `mart_sales_vs_target.employee_sk` | `dim_employees.employee_sk` |
| `fact_sales.customer_id`, `fact_returns.customer_id` | `dim_customers.customer_id` |
| `fact_sales.product_id`, `fact_returns.product_id` | `dim_products.product_id` |
| `mart_distributor_performance.distributor_sk` | `dim_distributors.distributor_sk` |

Nối nhân viên qua `employee_sk`, không qua `employee_id`. `employee_sk` đã được gắn theo thời gian (giao dịch tháng 3 gắn với giai đoạn của tháng 3), nên báo cáo lịch sử giữ đúng vùng và nhóm cũ sau khi nhân viên chuyển vùng.

## Quy tắc khi dùng

1. **Doanh thu bán hàng là `fact_sales.revenue_amount`**, không phải `net_amount`. `revenue_amount` chỉ tính đơn `Delivered` (A-01).
2. **Doanh thu thuần** = tổng `fact_sales.revenue_amount` trừ tổng `fact_returns.deducted_amount` (A-02). Trong `mart_sales_vs_target` đã tính sẵn ở cột `net_revenue`.
3. **`mart_sales_vs_target`: luôn lọc một phiên bản trước khi cộng.** Thực tế lặp lại ở mỗi phiên bản của cùng tháng (tháng 7 có cả dòng v1 và v2). Dùng `is_latest = TRUE` để so với chỉ tiêu hiện hành, hoặc lọc một `plan_version` cụ thể để so với phiên bản đó.
4. **% hoàn thành**: tính lại bằng tổng `net_revenue` chia tổng `target_revenue` trên các dòng có `achieve_pct` khác trống, không lấy trung bình cột `achieve_pct`.
5. **`mart_distributor_performance`**: `last_order_date`, `days_since_last_order`, `is_inactive_alert` lặp lại ở mọi tháng của cùng nhà phân phối. Đếm theo nhà phân phối (`DISTINCTCOUNT`), không cộng theo tháng.
6. **`date_key` của `fact_targets` và hai mart là ngày đầu tháng.** Xem theo tháng, quý, năm. Lọc theo một ngày cụ thể khác ngày 1 sẽ không có dữ liệu.
7. **`effective_to = 9999-12-31`** nghĩa là "chưa kết thúc". Không dùng cột này để tính số ngày.
8. **Không có YoY** vì chỉ có năm 2024 (L-01).

## Dimension

### dim_date

Lịch sinh tự động, 2022-01-01 đến 2026-12-31 (A-23). Đánh dấu là Date table trong Power BI.

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `date_key` | integer | Khóa, dạng `YYYYMMDD`, ví dụ `20240115` |
| `full_date` | date | Ngày |
| `day_of_month` | integer | Ngày trong tháng, 1 đến 31 |
| `day_of_week` | integer | 1 = Thứ Hai đến 7 = Chủ Nhật |
| `day_name` | text | Tên thứ: `Thứ Hai` ... `Chủ Nhật` |
| `is_weekend` | boolean | Thứ Bảy hoặc Chủ Nhật |
| `iso_week` | integer | Tuần theo chuẩn ISO |
| `month`, `quarter`, `year` | integer | Tháng, quý, năm dương lịch |
| `year_month` | text | Dạng `2024-01` |
| `fiscal_year` | integer | Năm tài chính 01/09 đến 31/08, đặt tên theo năm bắt đầu: 2024-01-01 thuộc FY2023 (A-22) |
| `fiscal_month` | integer | Tháng tài chính: tháng 9 = 1, tháng 8 = 12 |
| `fiscal_quarter` | integer | Quý tài chính: tháng 9 đến 11 = Q1 |
| `is_leap_day` | boolean | Ngày 29/02, bỏ qua khi so cùng kỳ (BRD) |

### dim_employees

Mỗi nhân viên có một bản ghi cho mỗi giai đoạn có vùng, nhóm, chức vụ hoặc trạng thái khác nhau (A-13). Hiện có 114 nhân viên, 13 người có 2 giai đoạn (5 chuyển vùng, 8 nghỉ việc), giai đoạn mới bắt đầu 2024-07-01.

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `employee_sk` | text | Khóa thay thế của giai đoạn: mã nhân viên và ngày bắt đầu, ví dụ `EMP1001_20240101` |
| `employee_id` | text | Mã nhân viên |
| `full_name`, `gender`, `date_of_birth`, `join_date` | | Thông tin cá nhân |
| `position` | text | `Sales Representative`, `Senior Sales Representative`, `Sales Supervisor`, `Area Manager` |
| `region` | text | Vùng trong giai đoạn: `Miền Bắc`, `Miền Trung`, `Miền Nam` |
| `team` | text | Nhóm trong giai đoạn, ví dụ `Team Nam 1`, `Management` |
| `status` | text | `Active` hoặc `Resigned` |
| `resign_date` | date | Ngày nghỉ việc thật (24/05 đến 18/06/2024), trống nếu đang làm |
| `transfer_note` | text | Ghi chú chuyển vùng, trống nếu không có |
| `effective_from`, `effective_to` | date | Khoảng hiệu lực của giai đoạn. `9999-12-31` = chưa kết thúc |
| `is_current` | boolean | TRUE ở giai đoạn mới nhất, mỗi nhân viên đúng một dòng |
| `source_version` | text | Ảnh chụp nguồn tạo ra giai đoạn: `v1` hoặc `v2` |

### dim_customers

Thông tin hiện tại của khách hàng. Không có số điện thoại, địa chỉ, mã số thuế (vẫn có ở `staging.stg_customers`).

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `customer_id` | text | Khóa |
| `customer_name` | text | Tên khách hàng |
| `customer_type` | text | Ví dụ `Tạp hóa`, `Siêu thị`, `Canteen` (6 loại) |
| `channel` | text | `Traditional Trade`, `Modern Trade`, `E-commerce` |
| `province`, `region` | text | Tỉnh, vùng |
| `status` | text | `Active` hoặc `Inactive` |
| `join_date` | date | Ngày bắt đầu giao dịch |
| `credit_limit` | numeric | Hạn mức công nợ (đồng) |
| `revenue_2024` | numeric | Doanh thu đơn `Delivered` năm 2024 |
| `loyalty_tier` | text | Hạng theo doanh thu 2024: `Vàng` (20% cao nhất), `Bạc` (30% kế), `Đồng`, `Chưa mua` (A-26) |

### dim_products

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `product_id` | text | Khóa |
| `product_name` | text | Tên sản phẩm |
| `category` | text | `Thực phẩm`, `Thức uống`, `Chăm sóc cá nhân`, `Gia dụng` |
| `sub_category`, `unit` | text | Nhóm con (17), đơn vị tính |
| `unit_price`, `cost_price` | numeric | Giá bán, giá vốn hiện tại (đồng) |
| `gross_margin_pct` | numeric | Biên lợi nhuận gộp: (giá bán − giá vốn) / giá bán × 100 |
| `weight_gram` | integer | Khối lượng (gram) |
| `status` | text | `Active` hoặc `Discontinued` |
| `launch_date` | date | Ngày ra mắt |

### dim_distributors

Có cấu trúc SCD Type 2 nhưng hiện mỗi nhà phân phối một bản ghi, vì nguồn chỉ có một ảnh chụp (A-14, L-05). Không có số điện thoại, email, người liên hệ, mã số thuế.

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `distributor_sk` | text | Khóa thay thế: mã nhà phân phối và ngày bắt đầu |
| `distributor_id`, `distributor_name` | text | Mã, tên |
| `tier` | text | `Nhà phân phối cấp 1`, `Đại lý cấp 2`, `Điểm bán lẻ` |
| `channel`, `province`, `region` | text | Kênh, tỉnh, vùng |
| `status` | text | `Active` hoặc `Inactive` |
| `join_date` | date | Ngày tham gia |
| `credit_limit` | numeric | Hạn mức công nợ (đồng) |
| `assigned_supervisor_id` | text | Mã nhân viên giám sát |
| `effective_from`, `effective_to`, `is_current` | | Khoảng hiệu lực (từ `join_date` đến `9999-12-31`) |

## Fact

### fact_sales

Giữ mọi dòng, kể cả `Cancelled` và `Delivering`. Dùng `revenue_amount` cho doanh thu.

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `order_id`, `product_id` | text | Khóa: một sản phẩm trong một đơn |
| `date_key`, `order_date` | | Ngày đặt hàng |
| `customer_id` | text | Khách hàng |
| `employee_sk`, `employee_id` | text | Nhân viên bán, `employee_sk` theo giai đoạn tại ngày đặt |
| `region`, `province`, `channel` | text | Vùng, tỉnh, kênh của giao dịch (có thể khác vùng của nhân viên) |
| `quantity` | integer | Số lượng |
| `unit_price` | numeric | Đơn giá trên giao dịch |
| `discount_amount`, `gross_amount`, `net_amount` | numeric | Chiết khấu, thành tiền trước và sau chiết khấu |
| `delivery_status` | text | `Delivered`, `Delivering`, `Cancelled` |
| `payment_method` | text | Hình thức thanh toán |
| `payment_status` | text | `Paid`, `Partial`, `Unpaid` |
| `is_delivered` | boolean | TRUE nếu `Delivered` |
| `revenue_amount` | numeric | **Doanh thu**: `net_amount` nếu `Delivered`, còn lại 0 (A-01) |
| `cost_amount` | numeric | Số lượng × giá vốn hiện tại (L-12) |
| `is_after_resign` | boolean | Ghi sau ngày nghỉ của nhân viên (547 dòng, A-25) |

### fact_targets

Giữ mọi phiên bản kế hoạch để so sánh (A-08).

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `employee_id`, `employee_sk` | text | Nhân viên, `employee_sk` theo giai đoạn tại ngày đầu tháng |
| `year`, `month`, `date_key` | integer | Tháng của chỉ tiêu, `date_key` là ngày đầu tháng |
| `plan_version`, `version_number` | | Phiên bản (`v1`, `v2`) và số thứ tự (1, 2) |
| `version_date` | date | Ngày ban hành phiên bản |
| `effective_from`, `effective_to` | date | Khoảng hiệu lực tính lại (A-06): v1 từ 01/01 đến 30/06, v2 từ 01/07 đến 31/12 |
| `is_latest` | boolean | TRUE nếu là phiên bản đang hiệu lực của tháng (1.284 dòng) |
| `is_active_month` | boolean | Nhân viên còn làm việc ngày đầu tháng (A-24) |
| `target_revenue` | numeric | Chỉ tiêu doanh thu (đồng) |
| `target_quantity`, `target_new_customers` | integer | Chỉ tiêu số lượng, khách hàng mới |

### fact_returns

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `return_id` | text | Khóa |
| `original_order_id`, `product_id` | text | Dòng đơn gốc trong `fact_sales` |
| `date_key`, `return_date` | | Ngày trả, quyết định kỳ bị trừ doanh thu (A-02) |
| `customer_id` | text | Khách hàng |
| `employee_sk`, `employee_id` | text | Nhân viên, theo giai đoạn tại ngày trả |
| `region` | text | Vùng |
| `return_quantity`, `unit_price`, `return_amount` | | Số lượng, đơn giá, thành tiền trả |
| `return_reason` | text | Lý do (6 loại), ví dụ `Hàng lỗi`, `Hàng hết hạn` |
| `status` | text | `Đã xử lý`, `Đang xử lý`, `Từ chối` |
| `is_deducted` | boolean | TRUE nếu `Đã xử lý` |
| `deducted_amount` | numeric | Số tiền trừ doanh thu: `return_amount` nếu `Đã xử lý`, còn lại 0 |

## Mart

### mart_sales_vs_target

Thực tế so chỉ tiêu theo nhân viên, tháng, phiên bản. **Lọc một phiên bản trước khi cộng** (quy tắc 3).

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `employee_sk`, `employee_id`, `full_name` | text | Nhân viên |
| `region`, `team` | text | Vùng, nhóm của nhân viên trong tháng đó (theo SCD2) |
| `year`, `month`, `date_key` | integer | Tháng |
| `plan_version` | text | Phiên bản. Trống nếu nhân viên có thực tế nhưng không có chỉ tiêu hiện hành (ví dụ hàng trả tháng 7 của người đã nghỉ) |
| `is_latest` | boolean | Dòng dùng để so với chỉ tiêu hiện hành |
| `is_active_month` | boolean | Còn làm việc ngày đầu tháng (A-24) |
| `target_revenue` | numeric | Chỉ tiêu của phiên bản |
| `actual_revenue` | numeric | Doanh thu `Delivered` của nhân viên trong tháng |
| `returns_amount` | numeric | Hàng trả `Đã xử lý` trong tháng |
| `net_revenue` | numeric | `actual_revenue` − `returns_amount` |
| `active_customers` | bigint | Số khách khác nhau có đơn `Delivered` trong tháng |
| `achieve_pct` | numeric | `net_revenue` / `target_revenue` × 100. Trống khi không có chỉ tiêu hoặc nhân viên không còn làm (A-12) |

Ghi chú: % hoàn thành toàn công ty khoảng 50% ở mọi tháng, là đặc điểm của dữ liệu (xem `docs/data_issues.md`, mục Quan sát từ Gold).

### mart_distributor_performance

Mỗi nhà phân phối có đủ 12 tháng, tháng không đặt hàng ghi 0. Đơn `Cancelled` bị loại khỏi số đơn, giá trị và Fill Rate (A-16).

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `distributor_sk`, `distributor_id`, `distributor_name` | text | Nhà phân phối |
| `tier`, `channel`, `region` | text | Cấp, kênh, vùng |
| `year`, `month`, `date_key` | integer | Tháng |
| `total_orders` | bigint | Số đơn khác nhau |
| `total_order_value` | numeric | Tổng giá trị đặt `gross_amount` (A-18) |
| `qty_ordered`, `qty_delivered` | bigint | Số lượng đặt, đã giao |
| `qty_delivered_ontime` | bigint | Số lượng giao đúng hạn (A-15) |
| `cancelled_lines` | bigint | Số dòng đơn bị hủy |
| `fill_rate_pct` | numeric | `qty_delivered_ontime` / `qty_ordered` × 100 (A-17). Trống khi không đặt hàng |
| `ontime_rate_pct` | numeric | % dòng đơn giao đúng hạn |
| `last_order_date` | date | Ngày đặt hàng gần nhất cả năm (lặp lại mọi tháng) |
| `days_since_last_order` | integer | Số ngày từ đơn gần nhất đến 2024-12-31 (A-05) |
| `is_inactive_alert` | boolean | TRUE nếu không đặt hàng quá 30 ngày (BRD 4.1) |

Fill Rate cả năm khoảng 34% trong khi tỷ lệ giao khoảng 85%: phần lớn đơn được giao nhưng trễ hạn.

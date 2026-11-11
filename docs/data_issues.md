# Data Issues: Bronze Profiling

## raw.sales_transactions (SRC-01)

| Chỉ số | Kết quả |
|---|---|
| Tổng số dòng | 119.101 |
| % null: order_id, order_date, customer_id, employee_id, product_id | 0% |
| Trùng theo (order_id, product_id) | 0 |
| Sai định dạng: order_date, quantity, unit_price, net_amount | 0 |

Giá trị phân loại viết thống nhất:
region (3), channel (3), delivery_status (3), payment_status (3).

**Khóa chính dự kiến ở Silver:** (order_id, product_id)

### Vấn đề và cách xử lý ở Silver

| Vấn đề | Cách xử lý |
|---|---|
| Mọi cột đang ở dạng chữ | Đổi kiểu: ngày sang DATE, số lượng sang INTEGER, tiền sang NUMERIC |
| net_amount, discount_amount có dạng 908000.0 | Dùng NUMERIC, không dùng INTEGER |
| 4.800 dòng delivery_status = Cancelled | Giữ ở Silver. Cần chốt có tính vào doanh số ở Gold không |

### Chưa kiểm tra

- customer_id, employee_id, product_id có tồn tại trong bảng danh mục không
- net_amount có khớp với gross_amount trừ discount_amount không

## raw.customers (SRC-03)

| Chỉ số | Kết quả |
|---|---|
| Tổng số dòng | 2.000 |
| % null: customer_id, customer_name, channel, region, phone, join_date | 0% |
| % null: tax_code | 51,75% (1.035 dòng) |
| Trùng theo customer_id | 0 |
| Sai định dạng: join_date, credit_limit, phone, tax_code (ô có giá trị) | 0 |

Giá trị phân loại viết thống nhất:
customer_type (6), channel (3), region (3), status (2: Active 1.843, Inactive 157).

**Khóa chính dự kiến ở Silver:** customer_id

### Vấn đề và cách xử lý ở Silver

| Vấn đề | Cách xử lý |
|---|---|
| Mọi cột đang ở dạng chữ | Đổi kiểu: join_date sang DATE, credit_limit sang NUMERIC |
| tax_code trống ở 51,75% số dòng | Đổi chuỗi rỗng thành NULL, giữ nguyên dòng. tax_code không phải cột bắt buộc |
| phone, tax_code là dãy số có thể bắt đầu bằng 0 | Giữ kiểu TEXT, không đổi sang số để không mất số 0 ở đầu |
| 157 khách hàng Inactive | Giữ lại, vì giao dịch cũ vẫn có thể tham chiếu đến họ |

## raw.products (SRC-04)

| Chỉ số | Kết quả |
|---|---|
| Tổng số dòng | 100 |
| % null: product_id, product_name, category, unit_price, cost_price, launch_date | 0% |
| Trùng theo product_id | 0 |
| Sai định dạng: unit_price, cost_price, weight_gram, launch_date | 0 |
| Giá vốn lớn hơn hoặc bằng giá bán, giá bán bằng 0 hoặc âm | 0 |

Giá trị phân loại viết thống nhất:
category (4), sub_category (17), unit (6), status (2: Active 92, Discontinued 8).

**Khóa chính dự kiến ở Silver:** product_id

### Vấn đề và cách xử lý ở Silver

| Vấn đề | Cách xử lý |
|---|---|
| Mọi cột đang ở dạng chữ | Đổi kiểu: unit_price, cost_price sang NUMERIC, weight_gram sang INTEGER, launch_date sang DATE |
| 8 sản phẩm Discontinued | Giữ lại, vì giao dịch cũ vẫn có thể tham chiếu đến chúng |

### Chưa kiểm tra

- unit_price trong bảng này có khớp với unit_price trong sales_transactions không (giá có thể thay đổi theo thời gian)

## raw.distributors (SRC-06)

| Chỉ số | Kết quả |
|---|---|
| Tổng số dòng | 138 |
| % null: distributor_id, distributor_name, tier, region, phone, email, tax_code, join_date, assigned_supervisor_id | 0% |
| Trùng theo distributor_id | 0 |
| Sai định dạng: join_date, credit_limit, phone, tax_code, email, assigned_supervisor_id | 0 |

Giá trị phân loại viết thống nhất:
tier (3: Đại lý cấp 2 59, Điểm bán lẻ 50, Nhà phân phối cấp 1 29), channel (3), region (3), status (2: Active 125, Inactive 13).

**Khóa chính dự kiến ở Silver:** distributor_id

### Vấn đề và cách xử lý ở Silver

| Vấn đề | Cách xử lý |
|---|---|
| Mọi cột đang ở dạng chữ | Đổi kiểu: join_date sang DATE, credit_limit sang NUMERIC. phone, tax_code giữ TEXT |
| 13 nhà phân phối Inactive | Giữ lại, vì đơn hàng cũ vẫn có thể tham chiếu đến họ |
| Đề bài yêu cầu dim_distributors theo SCD Type 2, nhưng nguồn chỉ có một ảnh chụp, không có phiên bản hay ngày hiệu lực | Chưa có lịch sử thay đổi để dựng SCD2. Tạm coi mỗi nhà phân phối có một bản ghi hiệu lực từ join_date. Cần hỏi Coach |

### Chưa kiểm tra

- assigned_supervisor_id có tồn tại trong employees không

## raw.employees (SRC-07)

| Chỉ số | Kết quả |
|---|---|
| Tổng số dòng | 228 (v1: 114, v2: 114) |
| % null: employee_id, full_name, position, region, team, status, version, effective_date | 0% |
| Trùng theo (employee_id, version) | 0 |
| Sai định dạng: date_of_birth, join_date, effective_date, resign_date, email, phone | 0 |

Giá trị phân loại viết thống nhất:
version (2), gender (2), position (4), region (3), team (10, gồm Management), status (2: Active, Resigned).

**Khóa chính dự kiến ở Silver:** (employee_id, version)

### Thay đổi giữa v1 (hiệu lực 2024-01-01) và v2 (hiệu lực 2024-07-01)

| Thay đổi | Số nhân viên |
|---|---|
| Đổi vùng và đổi team (có transfer_note) | 5 |
| Nghỉ việc: status Resigned, có resign_date | 8 |
| Đổi chức vụ | 0 |
| Không đổi | 101 |

Tổng 13 thay đổi, khớp với số dòng của sheet Change_Log (không nạp). resign_date chỉ có ở các dòng Resigned, nên trạng thái và ngày nghỉ khớp nhau.

### Vấn đề và cách xử lý ở Silver

| Vấn đề | Cách xử lý |
|---|---|
| Mọi cột đang ở dạng chữ | Đổi kiểu: date_of_birth, join_date, effective_date, resign_date sang DATE. phone giữ TEXT |
| resign_date, transfer_note trống ở đa số dòng | Đổi chuỗi rỗng thành NULL |
| v2 là ảnh chụp đầy đủ, nên 101 nhân viên không đổi có 2 dòng giống nhau (chỉ khác version) | Khi dựng dim_employees (SCD2), chỉ tạo bản ghi mới cho 13 nhân viên có thay đổi. Người không đổi giữ một bản ghi từ 2024-01-01 |

### Chưa kiểm tra

- ~~8 nhân viên nghỉ việc có phải là 8 nhân viên chỉ có trong chỉ tiêu v1 không~~ Đã kiểm tra: đúng (xem raw.sales_targets_raw)
- employee_id trong sales_transactions có tồn tại trong bảng này không

## raw.distributor_orders (SRC-05)

| Chỉ số | Kết quả |
|---|---|
| Tổng số dòng | 35.945 |
| % null: order_id, order_date, distributor_id, product_id, qty_ordered, qty_delivered, actual_delivery_date | 0% |
| Trùng theo (order_id, product_id) | 0 |
| Sai định dạng: 3 cột ngày, số lượng, giá, thành tiền, fill_rate_pct | 0 |
| Giao nhiều hơn đặt, đặt bằng 0, giao trước ngày đặt | 0 |
| fill_rate_pct, gross_amount, delivered_amount lệch so với công thức | 0 |
| ontime_delivery lệch so với ngày giao và ngày hẹn | **177** |

Giá trị phân loại viết thống nhất:
region (3), channel (3), product_category (4), delivery_status (3: Delivered 29.585, Partial 4.620, Cancelled 1.740), ontime_delivery (2), payment_terms (4).

**Khóa chính dự kiến ở Silver:** (order_id, product_id)

### Vấn đề và cách xử lý ở Silver

| Vấn đề | Cách xử lý |
|---|---|
| Mọi cột đang ở dạng chữ | Đổi kiểu: ngày sang DATE, số lượng sang INTEGER, giá, tiền, tỷ lệ sang NUMERIC |
| 177 dòng ontime_delivery = No nhưng giao sớm hoặc đúng hẹn (trễ từ -2 đến 0 ngày). Mọi dòng Yes đều khớp | Đề xuất tính lại cờ đúng hạn từ ngày giao và ngày hẹn, giữ cột gốc để đối chiếu. Cần chốt với Coach |
| 1.740 dòng Cancelled vẫn có ngày giao, số lượng giao và thành tiền lớn hơn 0 (tỷ lệ giao 68% đến 99,8%, giống hệt Delivered) | Trạng thái không khớp với số liệu. Cần hỏi Coach: đơn Cancelled có được tính vào hiệu suất nhà phân phối không |
| Không dòng nào giao đủ 100%: tỷ lệ giao cao nhất 99,8% ở cả Delivered | Delivered và Partial không phân biệt được bằng số lượng. Ghi chú khi tính fill rate ở mart_distributor_performance |

### Chưa kiểm tra

- distributor_id, product_id có tồn tại trong distributors, products không

## raw.return_transactions (SRC-09)

| Chỉ số | Kết quả |
|---|---|
| Tổng số dòng | 3.665 |
| % null: return_id, original_order_id, return_date, customer_id, product_id, return_quantity, return_amount, return_reason | 0% |
| Trùng theo return_id | 0 |
| Sai định dạng: return_date, return_month, return_quantity, unit_price, return_amount | 0 |
| return_amount lệch số lượng nhân đơn giá, return_month lệch tháng của return_date | 0 |

Giá trị phân loại viết thống nhất:
region (3), return_reason (6), status (3: Đã xử lý 2.990, Đang xử lý 506, Từ chối 169).

**Đối chiếu với sales_transactions** (ghép theo original_order_id và product_id): cả 3.665 phiếu đều tìm thấy dòng đơn gốc. Không phiếu nào trả nhiều hơn số đã mua, trả trước ngày mua, khác khách hàng, khác đơn giá, hay trả từ đơn đã hủy.

**Khóa chính dự kiến ở Silver:** return_id

### Vấn đề và cách xử lý ở Silver

| Vấn đề | Cách xử lý |
|---|---|
| Mọi cột đang ở dạng chữ | Đổi kiểu: return_date sang DATE, return_quantity sang INTEGER, unit_price, return_amount sang NUMERIC |
| 169 phiếu Từ chối và 506 phiếu Đang xử lý | Giữ ở Silver. Cần chốt ở Gold: chỉ trừ doanh số với phiếu Đã xử lý, hay cả phiếu Đang xử lý |

### Chưa kiểm tra

- Tổng số lượng trả của nhiều phiếu trên cùng một dòng đơn có vượt số đã mua không (mới kiểm tra từng phiếu riêng lẻ)

## raw.territory_mapping (SRC-08)

| Chỉ số | Kết quả |
|---|---|
| Tổng số dòng | 1.843 |
| % null: territory_id, employee_id, customer_id, region, team, effective_date, expiry_date, version | 0% |
| Trùng theo territory_id | 0 |
| Sai định dạng: effective_date, expiry_date | 0 |
| Ngày hết hạn trước ngày hiệu lực | 0 |
| Khách hàng bị giao chồng thời gian (cho cùng hoặc khác nhân viên) | 0 |

Giá trị phân loại viết thống nhất:
region (3), team (9), version (1: chỉ có v1).

Toàn bộ 1.843 dòng: version v1, hiệu lực 2024-01-01, hết hạn 9999-12-31 (chưa hết hạn). Mỗi khách đúng một dòng, giao cho 102 nhân viên.

**Đối chiếu với customers:** mọi customer_id đều tồn tại. 157 khách chưa được giao, và cả 157 đều là khách Inactive.

**Khóa chính dự kiến ở Silver:** territory_id (cũng duy nhất theo customer_id)

### Vấn đề và cách xử lý ở Silver

| Vấn đề | Cách xử lý |
|---|---|
| Mọi cột đang ở dạng chữ | Đổi effective_date, expiry_date sang DATE. Giữ 9999-12-31 làm quy ước "chưa hết hạn" |
| Phân vùng không được cập nhật sau đợt điều chỉnh nhân sự 2024-07-01 (employees v2): 196 khách vẫn giao cho 8 nhân viên đã nghỉ việc, 85 khách vẫn giao cho 5 nhân viên đã chuyển vùng | Giữ nguyên ở Silver. Cần hỏi Coach: có phiên bản v2 của phân vùng không, hay doanh số của các khách này từ tháng 7 được tính cho ai |

### Chưa kiểm tra

- employee_id trong sales_transactions có khớp với nhân viên được giao khách đó trong bảng này không

## raw.promotion_program (SRC-10)

| Chỉ số | Kết quả |
|---|---|
| Tổng số dòng | **80** (file nguồn có 40, đã nạp 2 lần) |
| % null: promotion_id, promotion_name, promotion_type, start_date, end_date, applicable_products, discount_pct, budget_vnd, status | 0% |
| Trùng theo promotion_id | **40 khóa, mỗi khóa 2 dòng**, toàn bộ do nạp 2 lần |
| Sai định dạng: 2 cột ngày, discount_pct, min_order_quantity, budget_vnd, actual_cost_vnd, applicable_products | 0 |
| Ngày kết thúc trước ngày bắt đầu, giảm giá trên 100% | 0 |
| Chi phí thực tế vượt ngân sách | 6 chương trình (tổng chi bằng 81,02% tổng ngân sách) |

Các số dưới đây đã tính cho 40 chương trình, tức một lần nạp:
promotion_type (5), target_channel (4, gồm All), target_region (4, gồm All), status (3: Completed 34, Active 3, Planned 3). Thời gian từ 2024-01-02 đến 2024-12-16.

**Đối chiếu với products:** applicable_products chứa nhiều mã trong một ô, ngăn cách bằng `|`. Tách ra được 145 cặp chương trình và sản phẩm, 71 sản phẩm khác nhau, mọi mã đều tồn tại trong products.

**Khóa chính dự kiến ở Silver:** promotion_id

### Vấn đề và cách xử lý ở Silver

| Vấn đề | Cách xử lý |
|---|---|
| Bảng bị nạp 2 lần (ingest_log: log_id 8 và 13), hai lần giống hệt nhau trừ cột metadata. Đây cũng là bằng chứng cho checkpoint Task 1.3 "chạy 2 lần thì số dòng tăng gấp đôi" | Khử trùng theo promotion_id, giữ bản có _ingested_at mới nhất |
| Mọi cột đang ở dạng chữ | Đổi kiểu: ngày sang DATE, discount_pct, budget_vnd, actual_cost_vnd sang NUMERIC, min_order_quantity sang INTEGER |
| applicable_products chứa nhiều mã trong một ô | Tách thành bảng phụ (promotion_id, product_id) bằng string_to_array và unnest |
| target_channel, target_region có giá trị All | Khi ghép với giao dịch, coi All là khớp với mọi kênh hoặc mọi vùng |
| 6 chương trình chi vượt ngân sách | Đây là thông tin nghiệp vụ, không phải lỗi dữ liệu. Giữ nguyên |

## raw.sales_targets_raw (SRC-02)

| Chỉ số | Kết quả |
|---|---|
| Tổng số dòng | 1.950 (v1: 1.332 = 111 nhân viên × 12 tháng, v2: 618 = 103 nhân viên × 6 tháng) |
| % null: plan_version, employee_id, year, month, 3 cột chỉ tiêu, effective_from | 0% |
| Trùng theo (employee_id, year, month, plan_version) | 0 |
| Sai định dạng: 3 cột ngày, year, month (1 đến 12), 3 cột chỉ tiêu | 0 |
| Chỉ tiêu bằng 0, ngày hết hạn trước ngày hiệu lực, tháng ngoài khoảng hiệu lực | 0 |

Giá trị phân loại viết thống nhất:
plan_version (2), region (3), team (9).

**Đối chiếu với employees** (cùng phiên bản: chỉ tiêu v1 với hồ sơ v1, chỉ tiêu v2 với hồ sơ v2):
- Mọi nhân viên có chỉ tiêu đều có hồ sơ cùng phiên bản. Vùng và team khớp 100%, nên 5 nhân viên chuyển vùng đã có chỉ tiêu v2 theo vùng mới.
- 8 nhân viên chỉ có chỉ tiêu v1 đúng là 8 nhân viên nghỉ việc (Resigned ở employees v2).
- 3 nhân viên không có chỉ tiêu nào đều là Area Manager.

**Khóa chính dự kiến ở Silver:** (employee_id, year, month, plan_version)

### Vấn đề và cách xử lý ở Silver

| Vấn đề | Cách xử lý |
|---|---|
| Mọi cột đang ở dạng chữ | Đổi kiểu: 3 cột ngày sang DATE, year, month, target_quantity, target_new_customers sang INTEGER, target_revenue sang NUMERIC |
| 8 nhân viên nghỉ việc vẫn có chỉ tiêu v1 cho tháng 7 đến 12 | Quy tắc "tháng 7 đến 12 dùng v2" sẽ bỏ chỉ tiêu nửa cuối năm của họ. Điều này hợp lý vì họ đã nghỉ từ 2024-07-01, nhưng cần xác nhận ở Task 2.3 |
| Area Manager không có chỉ tiêu | Đúng nghiệp vụ (cấp quản lý). Khi tính thực tế so với chỉ tiêu, Area Manager sẽ không có dòng chỉ tiêu |

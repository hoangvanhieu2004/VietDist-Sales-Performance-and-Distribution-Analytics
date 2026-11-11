# Assumptions Log

Dự án dùng 2 tài liệu hướng dẫn (Đề bài và BRD) và bộ dữ liệu có sẵn. Không có người phụ trách nghiệp vụ để hỏi, nên các câu hỏi mở được chốt bằng giả định hợp lý, trong phạm vi dữ liệu hiện có. Không tạo thêm dữ liệu. Yêu cầu nào dữ liệu không đủ để làm thì ghi vào phần **Hạn chế**.

Cột "Căn cứ" ghi nguồn của giả định: **BRD**, **Đề bài**, **Dữ liệu** (kết quả profiling trong `data_issues.md`), hoặc **Lựa chọn** (không có căn cứ trực tiếp, chọn theo cách phổ biến).

## Phạm vi dữ liệu

| Hạng mục | Phạm vi |
|---|---|
| Thời gian | 01/01/2024 đến 31/12/2024, đủ 12 tháng, chỉ một năm (sales_transactions, distributor_orders, return_transactions) |
| Nguồn | 10 nguồn SRC-01 đến SRC-10, tất cả trên Google Drive, định dạng CSV và XLSX |
| Phiên bản kế hoạch | v1 (hiệu lực 2024-01-01), v2 (hiệu lực 2024-07-01). Chưa có v3 |
| Phiên bản nhân viên | v1 (2024-01-01), v2 (2024-07-01) |
| Phân vùng | Chỉ v1 (2024-01-01) |
| Nhà phân phối | Một ảnh chụp, không có lịch sử |

## Giả định

### Doanh số và hàng trả (Branch A)

| ID | Giả định | Căn cứ |
|---|---|---|
| A-01 | Doanh thu thực tế = tổng `net_amount` (sau chiết khấu) của các dòng `delivery_status = Delivered`. Loại `Cancelled` (4.800 dòng) và `Delivering` (9.581 dòng) | BRD 3.1: "đơn hàng đã giao thành công". Chọn `net_amount` vì là số tiền sau chiết khấu |
| A-02 | Hàng trả chỉ trừ phiếu `Đã xử lý`, tính vào kỳ theo `return_date`. Phiếu `Từ chối` không trừ. Phiếu `Đang xử lý` hiển thị riêng, chưa trừ. Doanh thu thuần = A-01 trừ `return_amount` của phiếu `Đã xử lý` | BRD 3.1: Net Revenue = Gross Revenue – Returns, "trong kỳ" |
| A-03 | Doanh số gán cho nhân viên theo `employee_id` trên giao dịch, không theo `territory_mapping`. Phân vùng chỉ dùng cho câu hỏi "nhân viên nào phụ trách khách hàng lớn" (BR-A-03) | BRD 3.4: gắn nhân viên tại thời điểm phát sinh giao dịch. Dữ liệu: phân vùng không cập nhật sau tháng 7 |
| A-04 | Khách hàng mới trong tháng M = khách có đơn `Delivered` đầu tiên trong dữ liệu vào tháng M. Khách quay lại = có đơn trong tháng M và đã từng có đơn trước tháng M. Khách churn = khách `Active` không có đơn trong 90 ngày tính đến ngày tham chiếu | BRD OQ-03 còn mở. Lựa chọn: 90 ngày phổ biến với FMCG |
| A-05 | Ngày tham chiếu ("hôm nay") = 2024-12-31, ngày cuối của dữ liệu. Dùng cho cảnh báo không đặt hàng 30 ngày, churn và dự báo cuối kỳ | Dữ liệu dừng ở 2024-12-31 |

### Kế hoạch bán hàng (SRC-02)

| ID | Giả định | Căn cứ |
|---|---|---|
| A-06 | Ngày bắt đầu hiệu lực của phiên bản = `effective_from`. Ngày hết hạn = ngày trước ngày bắt đầu của phiên bản kế tiếp, phiên bản cuối hết hạn 2024-12-31. Không dùng cột `effective_to` của nguồn (ghi 2024-12-31 cho cả v1) | BRD 3.2: các phiên bản có hiệu lực nối tiếp, hỗ trợ không giới hạn phiên bản |
| A-07 | Kết quả: v1 hiệu lực 2024-01-01 đến 2024-06-30, v2 hiệu lực 2024-07-01 đến 2024-12-31 | Từ A-06 và dữ liệu |
| A-08 | Chỉ tiêu hiện hành của (nhân viên, tháng) = phiên bản mới nhất có hiệu lực trong tháng đó và có dòng cho nhân viên đó. Đánh dấu `is_latest = TRUE` cho dòng này, các phiên bản khác giữ lại với `is_latest = FALSE` để so sánh | BRD 3.1, 3.2: so với chỉ tiêu mới nhất, vẫn so được với từng phiên bản |
| A-09 | 8 nhân viên nghỉ việc từ 2024-07-01 không có chỉ tiêu tháng 7 đến 12. Chỉ tiêu v1 tháng 7 đến 12 của họ giữ lại (`is_latest = FALSE`) nhưng không tính vào % hoàn thành | Dữ liệu: đúng 8 người chỉ có v1 là 8 người Resigned |
| A-10 | Area Manager (3 người) không có chỉ tiêu, không tính % hoàn thành cho họ | Dữ liệu |
| A-11 | Chỉ tiêu phân bổ theo tháng. Khi xem theo quý, năm thì cộng các tháng | BRD OQ-08. Dữ liệu chỉ có tháng |
| A-12 | % hoàn thành = Thực tế (A-01, A-02) / Chỉ tiêu hiện hành. Chỉ tiêu bằng 0 hoặc không có thì để trống, không chia | BRD 3.1 |

### Nhân viên và nhà phân phối (SCD Type 2)

| ID | Giả định | Căn cứ |
|---|---|---|
| A-13 | `dim_employees`: mỗi nhân viên có bản ghi đầu hiệu lực từ 2024-01-01 (theo employees v1). 13 nhân viên thay đổi ở v2 (5 chuyển vùng và team, 8 nghỉ việc) được đóng bản ghi cũ ngày 2024-06-30 và tạo bản ghi mới từ 2024-07-01. 101 người không đổi giữ một bản ghi | Đề bài Subtask 3.1.2, BRD 3.4. Dữ liệu |
| A-14 | `dim_distributors`: dựng đúng cấu trúc SCD2 (`effective_from`, `effective_to`, `is_current`). Hiện mỗi nhà phân phối một bản ghi từ `join_date` đến 9999-12-31 | BRD 4.2. Dữ liệu chỉ có một ảnh chụp |

### Phân phối (Branch B)

| ID | Giả định | Căn cứ |
|---|---|---|
| A-15 | Cờ giao đúng hạn tính lại: `actual_delivery_date <= expected_delivery_date`. Giữ cột gốc `ontime_delivery` để đối chiếu (lệch 177 dòng) | Dữ liệu: ngày là dữ liệu gốc, cờ có thể nhập tay |
| A-16 | Đơn `Cancelled` (1.740 dòng) bị loại khỏi Total Orders, Total Order Value và Fill Rate, dù có số lượng giao | Lựa chọn: tôn trọng trạng thái do người dùng ghi |
| A-17 | Fill Rate tính theo dòng đơn: tổng `qty_delivered` của các dòng giao đúng hạn (A-15) / tổng `qty_ordered`, trên các dòng không Cancelled | BRD OQ-07 còn mở. Theo nghĩa đen "đúng hạn và đúng số 100%" thì Fill Rate = 0% vì không dòng nào giao đủ, nên dùng số lượng thực giao |
| A-18 | Total Order Value = tổng `gross_amount` (giá trị đặt) | BRD 4.1: "gross" |

### Khuyến mãi

| ID | Giả định | Căn cứ |
|---|---|---|
| A-19 | `promotion_program` khử trùng theo `promotion_id` (Bronze đang có 80 dòng do nạp 2 lần) | Dữ liệu |
| A-20 | Một dòng bán hàng thuộc chương trình KM nếu: `order_date` nằm trong khoảng `start_date` đến `end_date`, `product_id` có trong `applicable_products`, kênh và vùng khớp (giá trị `All` khớp mọi kênh, mọi vùng). Một dòng có thể thuộc nhiều chương trình, nên dùng bảng cầu (promotion_id, product_id) | BRD 3.3, 4.4: một sản phẩm thuộc nhiều KM cùng lúc |
| A-21 | ROI sơ bộ = (doanh thu trong kỳ KM – doanh thu kỳ ngay trước có cùng số ngày, cùng sản phẩm áp dụng) / `actual_cost_vnd`. Không tính cho chương trình `Planned` | BRD 4.4: so với trước kỳ KM. `actual_cost_vnd` có sẵn (trả lời một phần OQ-10) |

### Lịch

| ID | Giả định | Căn cứ |
|---|---|---|
| A-22 | Năm tài chính từ 01/09 đến 31/08, đặt tên theo năm bắt đầu (FY2023 = 2023-09-01 đến 2024-08-31). `dim_date` có cả năm dương lịch và năm tài chính | BRD 3.1 (làm rõ), Đề bài checkpoint Task 3.1 |
| A-23 | `dim_date` phủ 2022 đến 2026 theo đề bài, dù dữ liệu chỉ có 2024 | Đề bài checkpoint Task 3.1 |

## Hạn chế

Các yêu cầu dưới đây không làm được hoặc chỉ làm được một phần với dữ liệu hiện có. Mô hình được thiết kế để làm được khi có thêm dữ liệu.

| ID | Yêu cầu | Lý do | Cách xử lý hiện tại |
|---|---|---|---|
| L-01 | So sánh cùng kỳ năm trước (YoY) theo tháng, quý, YTD (BR-A-01, BR-B-01) | Dữ liệu chỉ có năm 2024 | Không tính. Measure YoY sẽ trả về trống |
| L-02 | So sánh theo năm tài chính | Dữ liệu chỉ phủ một phần FY2023 (01 đến 08/2024) và một phần FY2024 (09 đến 12/2024) | Vẫn gắn năm tài chính trong `dim_date`, nhưng hai năm tài chính đều thiếu tháng |
| L-03 | Chỉ tiêu và % đạt của nhà phân phối (BR-B-02) | Không có nguồn chỉ tiêu nhà phân phối (OQ-06) | Bỏ qua |
| L-04 | Tồn kho, Days of Supply, reorder point, slow-moving (BR-B-03) | Không có nguồn tồn kho (OQ-04, OQ-05, OQ-09) | Bỏ qua |
| L-05 | Lịch sử thay đổi cấp độ, vùng của nhà phân phối (BR-B-02) | Nguồn chỉ có một ảnh chụp | Có cấu trúc SCD2 (A-14) nhưng chưa có lịch sử |
| L-06 | Phân vùng khách hàng từ tháng 7 | Không có phân vùng v2: 196 khách vẫn giao cho 8 nhân viên đã nghỉ, 85 khách cho 5 nhân viên đã chuyển vùng | Doanh số không phụ thuộc phân vùng (A-03). Báo cáo phân công khách hàng chỉ đúng cho nửa đầu năm |
| L-07 | Khách hàng mới, quay lại, churn | Dữ liệu bắt đầu từ 01/2024, nên mọi khách đều "mới" trong tháng đầu tiên họ xuất hiện | Số khách mới các tháng đầu năm bị thổi phồng. Chỉ nên đọc chỉ số này từ khoảng tháng 4 trở đi |
| L-08 | Kế hoạch v3 và các phiên bản sau | Chưa có dữ liệu | Logic A-06 tự xử lý khi có phiên bản mới |
| L-09 | Ghi lại người thực hiện thay đổi kế hoạch (BRD 5.3) | Nguồn không có thông tin người thay đổi | Chỉ có `version_date` và thời điểm nạp (`_ingested_at`, `raw.sales_target_files`) |
| L-10 | Fill Rate theo đúng nghĩa "đúng hạn và đúng số" | Không dòng nào giao đủ 100% | Dùng định nghĩa A-17 |
| L-11 | Đọc file XLSB, XLSM và nguồn trên OneDrive | Bộ dữ liệu chỉ có CSV và XLSX trên Google Drive | Code đọc XLSB, XLSM có sẵn nhưng chưa thử với file thật. Chưa viết kết nối OneDrive |

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
| A-03 | Doanh số gán cho nhân viên theo `employee_id` trên giao dịch, không theo `territory_mapping`. Câu hỏi "nhân viên nào phụ trách khách hàng lớn" (BR-A-03) cũng trả lời bằng nhân viên đứng tên giao dịch trong `fact_sales`: một khách lớn có thể hiện nhiều nhân viên kèm doanh thu từng người. Sửa đổi: ban đầu định dùng phân vùng cho câu hỏi này, nhưng Gold giữ đúng cấu trúc đề bài và không có bảng phân vùng | BRD 3.4: gắn nhân viên tại thời điểm phát sinh giao dịch. Dữ liệu: phân vùng không cập nhật sau tháng 7. Lựa chọn của người dùng: không thêm cột ngoài đề bài vào Gold |
| A-04 | Khách hàng mới trong tháng M = khách có đơn `Delivered` đầu tiên trong dữ liệu vào tháng M. Khách quay lại = có đơn trong tháng M và đã từng có đơn trước tháng M. Khách churn = khách `Active` không có đơn trong 90 ngày tính đến ngày tham chiếu | BRD OQ-03 còn mở. Lựa chọn: 90 ngày phổ biến với FMCG |
| A-26 | Hạng khách hàng (loyalty tier, Đề bài Task 3.1) tính từ doanh thu `Delivered` năm 2024: 20% khách cao nhất là Vàng, 30% kế tiếp là Bạc, còn lại là Đồng, khách chưa có đơn giao thành công là Chưa mua. Xếp bằng `PERCENT_RANK` trên các khách đã mua | Đề bài yêu cầu loyalty tier nhưng nguồn không có cột này. Lựa chọn: ngưỡng 20/30/50 theo nguyên tắc Pareto |
| A-27 | Xu hướng nhân viên (BR-A-04): so doanh thu `Delivered` (chưa trừ hàng trả) 6 tháng cuối năm với 6 tháng đầu năm. Tăng từ 10% trở lên là Tăng trưởng tốt, giảm từ 10% trở lên là Sa sút, còn lại là Ổn định. Không xếp loại nếu một trong hai nửa năm không có doanh thu | BRD 3.4 không định nghĩa cách đo. Lựa chọn: gộp 6 tháng để giảm dao động ngẫu nhiên từng tháng, ngưỡng ±10%. Không trừ hàng trả vì phiếu trả xử lý muộn làm lệch xu hướng |
| A-05 | Ngày tham chiếu ("hôm nay") = 2024-12-31, ngày cuối của dữ liệu. Dùng cho cảnh báo không đặt hàng 30 ngày, churn và dự báo cuối kỳ | Dữ liệu dừng ở 2024-12-31 |

### Kế hoạch bán hàng (SRC-02)

| ID | Giả định | Căn cứ |
|---|---|---|
| A-06 | Ngày bắt đầu hiệu lực của phiên bản = `effective_from`. Ngày hết hạn = ngày trước ngày bắt đầu của phiên bản kế tiếp, phiên bản cuối hết hạn 2024-12-31. Không dùng cột `effective_to` của nguồn (ghi 2024-12-31 cho cả v1) | BRD 3.2: các phiên bản có hiệu lực nối tiếp, hỗ trợ không giới hạn phiên bản |
| A-07 | Kết quả: v1 hiệu lực 2024-01-01 đến 2024-06-30, v2 hiệu lực 2024-07-01 đến 2024-12-31 | Từ A-06 và dữ liệu |
| A-08 | Phiên bản hiệu lực được xác định theo tháng cho toàn kế hoạch: là phiên bản có khoảng hiệu lực (A-06) chứa ngày đầu tháng. Dòng chỉ tiêu thuộc phiên bản đó có `is_latest = TRUE`, các phiên bản khác giữ lại với `is_latest = FALSE` để so sánh. Nhân viên không có dòng ở phiên bản hiệu lực thì không có chỉ tiêu hiện hành trong tháng đó | BRD 3.1, 3.2: so với chỉ tiêu mới nhất, vẫn so được với từng phiên bản |
| A-09 | 8 nhân viên nghỉ việc (resign_date từ 2024-05-24 đến 2024-06-18) không có chỉ tiêu hiện hành từ tháng 7, vì v2 không có họ. Chỉ tiêu v1 tháng 7 đến 12 của họ giữ lại với `is_latest = FALSE`. Chỉ tiêu v1 tháng 6 vẫn là `is_latest = TRUE`, vì tháng 6 còn áp dụng v1 | Dữ liệu: đúng 8 người chỉ có v1 là 8 người Resigned |
| A-10 | Area Manager (3 người) không có chỉ tiêu, không tính % hoàn thành cho họ | Dữ liệu |
| A-11 | Chỉ tiêu phân bổ theo tháng. Khi xem theo quý, năm thì cộng các tháng | BRD OQ-08. Dữ liệu chỉ có tháng |
| A-12 | % hoàn thành = Thực tế (A-01, A-02) / Chỉ tiêu hiện hành. Chỉ tiêu bằng 0 hoặc không có thì để trống, không chia | BRD 3.1 |
| A-24 | % hoàn thành cá nhân chỉ tính cho tháng mà nhân viên còn làm việc vào ngày đầu tháng (chưa nghỉ, hoặc resign_date sau ngày đầu tháng). Ví dụ EMP1054 nghỉ 24/05 thì không tính tháng 6 | Lựa chọn: tránh chấm % hoàn thành cho người đã nghỉ cả tháng. Dữ liệu: 3 người nghỉ trước 01/06 vẫn có chỉ tiêu v1 tháng 6 |
| A-25 | Doanh số ghi sau ngày nghỉ (547 dòng, 0,463% tổng doanh số, từ 30/05 đến 30/06) vẫn tính cho nhân viên ghi trên giao dịch, theo A-03, và vẫn cộng vào tổng nhóm, vùng. Gold thêm cờ `is_after_resign` để báo cáo thấy được. Theo A-24, các tháng này không tính % hoàn thành cá nhân của họ | Dữ liệu: không có giao dịch nào của họ từ tháng 7, nên nhiều khả năng là giai đoạn bàn giao |

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
| A-28 | Xu hướng nhà phân phối (BR-B-01): so giá trị đặt hàng (A-18, không tính đơn `Cancelled`) 6 tháng cuối năm với 6 tháng đầu năm. Giảm từ 10% trở lên là Giảm sút, tăng từ 10% trở lên là Tăng trưởng, còn lại là Ổn định. Không xếp loại nếu một trong hai nửa năm không đặt hàng | BRD 4.1 không định nghĩa "giảm sút". Lựa chọn: cùng logic với A-27 để cả báo cáo đo xu hướng một cách |

### Khuyến mãi

| ID | Giả định | Căn cứ |
|---|---|---|
| A-19 | `promotion_program` khử trùng theo `promotion_id` (Bronze đang có 80 dòng do nạp 2 lần) | Dữ liệu |
| A-20 | Một dòng bán hàng thuộc chương trình KM nếu: `order_date` nằm trong khoảng `start_date` đến `end_date`, `product_id` có trong `applicable_products`, kênh và vùng khớp (giá trị `All` khớp mọi kênh, mọi vùng). Một dòng có thể thuộc nhiều chương trình. Danh sách sản phẩm của mỗi chương trình được tách thành cột mảng `applicable_product_ids` trong `stg_promotion_program` (không tạo bảng riêng), và dàn ra bằng `unnest` khi cần | BRD 3.3, 4.4: một sản phẩm thuộc nhiều KM cùng lúc |
| A-21 | ROI sơ bộ = (doanh thu trong kỳ KM – doanh thu kỳ ngay trước có cùng số ngày, cùng sản phẩm áp dụng) / `actual_cost_vnd`. Không tính cho chương trình `Planned` | BRD 4.4: so với trước kỳ KM. `actual_cost_vnd` có sẵn (trả lời một phần OQ-10) |

### Lịch

| ID | Giả định | Căn cứ |
|---|---|---|
| A-22 | Năm tài chính từ 01/09 đến 31/08, đặt tên theo năm bắt đầu (FY2023 = 2023-09-01 đến 2024-08-31). `dim_date` có cả năm dương lịch và năm tài chính | BRD 3.1 (làm rõ), Đề bài checkpoint Task 3.1 |
| A-23 | `dim_date` phủ 2022 đến 2026 theo đề bài, dù dữ liệu chỉ có 2024 | Đề bài checkpoint Task 3.1 |

### Phân quyền (Row-Level Security)

| ID | Giả định | Căn cứ |
|---|---|---|
| A-29 | Role lọc trên `dim_employees` (lan xuống dữ liệu Branch A) và `dim_distributors` (lan xuống Branch B). Ban Giám đốc không lọc. Giám đốc Vùng lọc cả nhân viên và nhà phân phối theo vùng. Trưởng nhóm lọc `team`, nhân viên Sales lọc `employee_id`, cả hai không thấy dữ liệu nhà phân phối. Quản lý nhà phân phối lọc `assigned_supervisor_id`, không thấy dữ liệu nhân viên. Vùng của nhân viên theo giai đoạn SCD2, nên giám đốc chỉ thấy doanh số làm ra khi nhân viên còn thuộc vùng mình | BRD 5.2. Lựa chọn: tách Branch A và B theo trách nhiệm của từng cấp |

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
| L-12 | Giá vốn và biên lợi nhuận tại thời điểm bán | Nguồn chỉ có giá vốn hiện tại (product_master), không có lịch sử giá vốn | `fact_sales.cost_amount` = số lượng nhân giá vốn hiện tại. Biên lợi nhuận theo thời gian có thể lệch nếu giá vốn đã đổi trong năm |
| L-11 | Đọc file XLSB, XLSM và nguồn trên OneDrive | Bộ dữ liệu chỉ có CSV và XLSX trên Google Drive | Code đọc XLSB, XLSM có sẵn nhưng chưa thử với file thật. Chưa viết kết nối OneDrive |
| L-13 | Doanh thu trong và ngoài kỳ khuyến mãi (BR-A-03) và toàn bộ báo cáo hiệu quả khuyến mãi (BR-B-04) | Mô hình Gold theo đề bài không có bảng hay cột khuyến mãi. Danh sách sản phẩm của chương trình chỉ có ở Silver, dạng cột mảng mà Power BI không đọc được | Bỏ qua. `staging.stg_promotion_program` vẫn có đủ dữ liệu để làm sau nếu bổ sung đối tượng Gold |
| L-14 | Dự báo cuối tháng, cuối quý sẽ đạt bao nhiêu phần trăm (BR-A-01) | Ngày tham chiếu là 2024-12-31 (A-05), mọi tháng và quý đã kết thúc nên không còn kỳ nào để dự báo | Bỏ qua. Trang ghi chú lý do |
| L-15 | Lịch sử nhân viên "từ khi vào đến nay" (BR-A-04) | Nguồn chỉ có 2 ảnh chụp (đầu năm và 01/07/2024) và không có bán hàng trước 2024, trong khi nhân viên vào làm từ 2010 | Hiện `join_date`. Lịch sử vùng, nhóm và doanh thu chỉ bắt đầu từ 01/01/2024 |
| L-16 | Xem đơn nhà phân phối theo ngày, theo tuần (BR-B-01) | Gold theo đề bài chỉ có `mart_distributor_performance` theo tháng, không có fact đơn nhà phân phối theo ngày | Chỉ xem theo tháng và quý. Dữ liệu theo ngày vẫn có ở `staging.stg_distributor_orders` |
| L-17 | Phân quyền tự động theo người đăng nhập (`USERPRINCIPALNAME()`, BRD 5.2) | Gold không có email nhân viên, và Power BI Desktop không có người đăng nhập thật | Tạo role tĩnh: 1 role Ban Giám đốc, 3 role Giám đốc Vùng và 1 role mẫu cho mỗi cấp còn lại. Khi lên Power BI Service thì gán email vào role, hoặc bổ sung bảng ánh xạ email để dùng role động |
